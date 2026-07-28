import http from 'node:http';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const MAX_PLAYERS = 4;
const MIN_PLAYERS = 2;
const ROOM_CODE_LENGTH = 4;
const ROOM_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const ROOM_TTL_MS = 2 * 60 * 60 * 1000;
const CLIENT_TTL_MS = 45 * 1000;
const MAX_QUEUE_MESSAGES = 128;

const rooms = globalThis.__conquestCartesRooms ?? new Map();
globalThis.__conquestCartesRooms = rooms;

export default async function handler(request, response) {
  setCorsHeaders(response);

  if (request.method === 'OPTIONS') {
    response.statusCode = 204;
    response.end();
    return;
  }

  if (request.method === 'GET') {
    sendJson(response, 200, {
      ok: true,
      service: 'conquest-cartes-relay',
      transport: 'http-poll',
      rooms: rooms.size,
    });
    return;
  }

  if (request.method !== 'POST') {
    sendJson(response, 405, {
      ok: false,
      messages: [{ type: 'error', code: 'bad_method', message: 'Use POST for relay messages.' }],
    });
    return;
  }

  let message;
  try {
    message = await readJsonBody(request);
  } catch (_error) {
    sendJson(response, 400, {
      ok: false,
      messages: [{ type: 'error', code: 'bad_json', message: 'Relay messages must be JSON.' }],
    });
    return;
  }

  pruneRooms();

  switch (String(message.type ?? '')) {
    case 'create':
      createRoom(response, message);
      break;
    case 'join':
      joinRoom(response, message);
      break;
    case 'poll':
      pollRoom(response, message);
      break;
    case 'signal':
      relaySignal(response, message);
      break;
    case 'leave':
      leaveRoom(response, message);
      break;
    case 'ping':
      sendRelayMessages(response, [{ type: 'pong', now: Date.now() }]);
      break;
    default:
      sendRelayError(response, 'unknown_type', 'Unknown relay message type.');
  }
}

function createRoom(response, message) {
  const maxPlayers = clampInt(message.maxPlayers, MIN_PLAYERS, MAX_PLAYERS, MAX_PLAYERS);
  const client = createClient('host');
  const code = nextRoomCode();
  const room = {
    code,
    maxPlayers,
    hostId: client.id,
    clients: new Map([[client.id, client]]),
    createdAt: Date.now(),
    lastSeenAt: Date.now(),
  };

  rooms.set(code, room);

  sendRelayMessages(response, [
    { type: 'hello', clientId: client.id },
    {
      type: 'created',
      code,
      clientId: client.id,
      maxPlayers,
    },
  ]);
}

function joinRoom(response, message) {
  const code = normalizeCode(message.code);
  if (code.length !== ROOM_CODE_LENGTH) {
    sendRelayError(response, 'bad_code', 'Enter a 4-letter lobby code.');
    return;
  }

  const room = rooms.get(code);
  if (!room || !room.clients.has(room.hostId)) {
    sendRelayError(response, 'not_found', 'No open lobby found for that code.');
    return;
  }

  pruneRoomClients(room);
  if (room.clients.size >= room.maxPlayers) {
    sendRelayError(response, 'full', 'That lobby is already full.');
    return;
  }

  const client = createClient('client');
  room.clients.set(client.id, client);
  touchRoom(room, client);

  enqueueForClient(room, room.hostId, {
    type: 'peer_joined',
    code,
    clientId: client.id,
    playerCount: room.clients.size,
  });

  sendRelayMessages(response, [
    { type: 'hello', clientId: client.id },
    {
      type: 'joined',
      code,
      clientId: client.id,
      hostId: room.hostId,
      maxPlayers: room.maxPlayers,
    },
  ]);
}

function pollRoom(response, message) {
  const lookup = roomAndClientForMessage(message);
  if (!lookup.room || !lookup.client) {
    sendRelayError(response, 'not_found', 'No open lobby found for that code.');
    return;
  }

  touchRoom(lookup.room, lookup.client);
  const messages = lookup.client.queue.splice(0, lookup.client.queue.length);
  sendRelayMessages(response, messages);
}

function relaySignal(response, message) {
  const lookup = roomAndClientForMessage(message);
  if (!lookup.room || !lookup.client) {
    sendRelayError(response, 'no_room', 'Join or create a lobby before sending game messages.');
    return;
  }

  touchRoom(lookup.room, lookup.client);
  const target = String(message.target ?? (lookup.client.role === 'host' ? 'all' : 'host'));
  const signal = {
    type: 'signal',
    code: lookup.room.code,
    from: lookup.client.id,
    payload: message.payload ?? {},
  };

  if (lookup.client.role !== 'host') {
    enqueueForClient(lookup.room, lookup.room.hostId, signal);
    sendRelayMessages(response, []);
    return;
  }

  if (target === 'all') {
    for (const peer of lookup.room.clients.values()) {
      if (peer.id !== lookup.client.id) {
        enqueue(peer, signal);
      }
    }
    sendRelayMessages(response, []);
    return;
  }

  if (target === 'host') {
    enqueueForClient(lookup.room, lookup.room.hostId, signal);
    sendRelayMessages(response, []);
    return;
  }

  enqueueForClient(lookup.room, target, signal);
  sendRelayMessages(response, []);
}

function leaveRoom(response, message) {
  const lookup = roomAndClientForMessage(message);
  if (!lookup.room || !lookup.client) {
    sendRelayMessages(response, []);
    return;
  }

  removeClientFromRoom(lookup.room, lookup.client.id);
  sendRelayMessages(response, []);
}

function roomAndClientForMessage(message) {
  const code = normalizeCode(message.code);
  const clientId = String(message.clientId ?? '');
  const room = rooms.get(code);
  if (!room || clientId.length === 0) {
    return { room: null, client: null };
  }
  const client = room.clients.get(clientId);
  return { room, client: client ?? null };
}

function createClient(role) {
  return {
    id: randomUUID(),
    role,
    queue: [],
    lastSeenAt: Date.now(),
  };
}

function touchRoom(room, client) {
  const now = Date.now();
  room.lastSeenAt = now;
  client.lastSeenAt = now;
}

function enqueueForClient(room, clientId, message) {
  const target = room.clients.get(clientId);
  if (target) {
    enqueue(target, message);
  }
}

function enqueue(client, message) {
  client.queue.push(message);
  if (client.queue.length > MAX_QUEUE_MESSAGES) {
    client.queue.splice(0, client.queue.length - MAX_QUEUE_MESSAGES);
  }
}

function removeClientFromRoom(room, clientId) {
  room.clients.delete(clientId);

  if (clientId === room.hostId) {
    for (const peer of room.clients.values()) {
      enqueue(peer, {
        type: 'closed',
        code: room.code,
        reason: 'host_disconnected',
      });
    }
    rooms.delete(room.code);
    return;
  }

  enqueueForClient(room, room.hostId, {
    type: 'peer_left',
    code: room.code,
    clientId,
    playerCount: room.clients.size,
  });

  if (room.clients.size === 0) {
    rooms.delete(room.code);
  }
}

function pruneRooms() {
  const now = Date.now();
  for (const room of [...rooms.values()]) {
    pruneRoomClients(room, now);
    if (
      now - room.lastSeenAt > ROOM_TTL_MS
      || !room.clients.has(room.hostId)
      || room.clients.size === 0
    ) {
      rooms.delete(room.code);
    }
  }
}

function pruneRoomClients(room, now = Date.now()) {
  for (const client of [...room.clients.values()]) {
    if (now - client.lastSeenAt > CLIENT_TTL_MS) {
      removeClientFromRoom(room, client.id);
    }
  }
}

function sendRelayMessages(response, messages, statusCode = 200) {
  sendJson(response, statusCode, {
    ok: statusCode >= 200 && statusCode < 300,
    messages,
  });
}

function sendRelayError(response, code, message, statusCode = 200) {
  sendRelayMessages(response, [{ type: 'error', code, message }], statusCode);
}

function setCorsHeaders(response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  // The web build is cross-origin isolated (COEP: require-corp) so it can use
  // threads; this header lets that isolated page read the relay's responses.
  response.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
}

function sendJson(response, statusCode, payload) {
  response.statusCode = statusCode;
  response.setHeader('content-type', 'application/json; charset=utf-8');
  response.end(JSON.stringify(payload));
}

async function readJsonBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(Buffer.from(chunk));
  }
  const text = Buffer.concat(chunks).toString('utf8');
  return text.length === 0 ? {} : JSON.parse(text);
}

function nextRoomCode() {
  for (let attempt = 0; attempt < 200; attempt += 1) {
    const code = generateCode();
    if (!rooms.has(code)) {
      return code;
    }
  }
  throw new Error('Could not allocate a room code.');
}

function generateCode() {
  let code = '';
  for (let index = 0; index < ROOM_CODE_LENGTH; index += 1) {
    const offset = Math.floor(Math.random() * ROOM_CODE_ALPHABET.length);
    code += ROOM_CODE_ALPHABET[offset];
  }
  return code;
}

function normalizeCode(value) {
  return String(value ?? '')
    .toUpperCase()
    .replace(/[^A-Z]/g, '')
    .slice(0, ROOM_CODE_LENGTH);
}

function clampInt(value, min, max, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, parsed));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const port = Number.parseInt(process.env.PORT ?? '3000', 10);
  const server = http.createServer((request, response) => {
    handler(request, response).catch((error) => {
      console.error(error);
      sendJson(response, 500, {
        ok: false,
        messages: [{ type: 'error', code: 'server_error', message: 'Relay server error.' }],
      });
    });
  });

  // Bind on 0.0.0.0 so cloud hosts (Render/Fly/Railway) can route to us; they
  // inject the port via PORT. Room state lives in this single process, so run
  // exactly ONE instance (no serverless, no autoscaling to multiple replicas).
  const host = process.env.HOST ?? '0.0.0.0';
  server.listen(port, host, () => {
    console.log(`Conquest Cartes relay listening on ${host}:${port} (POST /api/relay)`);
  });
}
