import http from 'node:http';
import { randomUUID } from 'node:crypto';
import { WebSocket, WebSocketServer } from 'ws';

const MAX_PLAYERS = 4;
const MIN_PLAYERS = 2;
const ROOM_CODE_LENGTH = 4;
const ROOM_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const ROOM_TTL_MS = 2 * 60 * 60 * 1000;
const HEARTBEAT_MS = 25000;

const rooms = globalThis.__conquestCartesRooms ?? new Map();
globalThis.__conquestCartesRooms = rooms;

const server = http.createServer((_request, response) => {
  response.statusCode = 200;
  response.setHeader('content-type', 'application/json; charset=utf-8');
  response.end(JSON.stringify({ ok: true, service: 'conquest-cartes-relay' }));
});

const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  const client = {
    id: randomUUID(),
    ws,
    roomCode: '',
    role: 'guest',
    isAlive: true,
  };

  ws.on('pong', () => {
    client.isAlive = true;
  });

  ws.on('message', (raw) => {
    handleMessage(client, raw);
  });

  ws.on('close', () => {
    handleClose(client);
  });

  send(client, { type: 'hello', clientId: client.id });
});

function handleMessage(client, raw) {
  let message;
  try {
    message = JSON.parse(raw.toString());
  } catch (_error) {
    sendError(client, 'bad_json', 'Relay messages must be JSON.');
    return;
  }

  pruneRooms();

  switch (String(message.type ?? '')) {
    case 'create':
      createRoom(client, message);
      break;
    case 'join':
      joinRoom(client, message);
      break;
    case 'signal':
      relaySignal(client, message);
      break;
    case 'ping':
      send(client, { type: 'pong', now: Date.now() });
      break;
    default:
      sendError(client, 'unknown_type', 'Unknown relay message type.');
  }
}

function createRoom(client, message) {
  leaveCurrentRoom(client);

  const maxPlayers = clampInt(message.maxPlayers, MIN_PLAYERS, MAX_PLAYERS, MAX_PLAYERS);
  const code = nextRoomCode();
  const room = {
    code,
    maxPlayers,
    hostId: client.id,
    clients: new Map([[client.id, client]]),
    createdAt: Date.now(),
    lastSeenAt: Date.now(),
  };

  client.roomCode = code;
  client.role = 'host';
  rooms.set(code, room);

  send(client, {
    type: 'created',
    code,
    clientId: client.id,
    maxPlayers,
  });
}

function joinRoom(client, message) {
  leaveCurrentRoom(client);

  const code = normalizeCode(message.code);
  if (code.length !== ROOM_CODE_LENGTH) {
    sendError(client, 'bad_code', 'Enter a 4-letter lobby code.');
    return;
  }

  const room = rooms.get(code);
  if (!room || !room.clients.has(room.hostId)) {
    sendError(client, 'not_found', 'No open lobby found for that code.');
    return;
  }
  if (room.clients.size >= room.maxPlayers) {
    sendError(client, 'full', 'That lobby is already full.');
    return;
  }

  client.roomCode = code;
  client.role = 'client';
  room.clients.set(client.id, client);
  room.lastSeenAt = Date.now();

  send(client, {
    type: 'joined',
    code,
    clientId: client.id,
    hostId: room.hostId,
    maxPlayers: room.maxPlayers,
  });

  sendToId(room, room.hostId, {
    type: 'peer_joined',
    code,
    clientId: client.id,
    playerCount: room.clients.size,
  });
}

function relaySignal(client, message) {
  const room = roomForClient(client);
  if (!room) {
    sendError(client, 'no_room', 'Join or create a lobby before sending game messages.');
    return;
  }

  room.lastSeenAt = Date.now();
  const target = String(message.target ?? (client.role === 'host' ? 'all' : 'host'));
  const signal = {
    type: 'signal',
    code: room.code,
    from: client.id,
    payload: message.payload ?? {},
  };

  if (client.role !== 'host') {
    sendToId(room, room.hostId, signal);
    return;
  }

  if (target === 'all') {
    for (const peer of room.clients.values()) {
      if (peer.id !== client.id) {
        send(peer, signal);
      }
    }
    return;
  }

  if (target === 'host') {
    sendToId(room, room.hostId, signal);
    return;
  }

  sendToId(room, target, signal);
}

function handleClose(client) {
  leaveCurrentRoom(client, true);
}

function leaveCurrentRoom(client, closing = false) {
  if (!client.roomCode) {
    return;
  }

  const room = rooms.get(client.roomCode);
  if (!room) {
    client.roomCode = '';
    client.role = 'guest';
    return;
  }

  room.clients.delete(client.id);

  if (client.id === room.hostId) {
    for (const peer of room.clients.values()) {
      send(peer, {
        type: 'closed',
        code: room.code,
        reason: 'host_disconnected',
      });
      peer.roomCode = '';
      peer.role = 'guest';
    }
    rooms.delete(room.code);
  } else {
    sendToId(room, room.hostId, {
      type: 'peer_left',
      code: room.code,
      clientId: client.id,
      playerCount: room.clients.size,
    });
    if (room.clients.size === 0) {
      rooms.delete(room.code);
    }
  }

  if (!closing) {
    client.roomCode = '';
    client.role = 'guest';
  }
}

function roomForClient(client) {
  if (!client.roomCode) {
    return null;
  }
  const room = rooms.get(client.roomCode);
  if (!room || !room.clients.has(client.id)) {
    return null;
  }
  return room;
}

function sendToId(room, clientId, message) {
  const target = room.clients.get(clientId);
  if (target) {
    send(target, message);
  }
}

function send(client, message) {
  if (client.ws.readyState !== WebSocket.OPEN) {
    return;
  }
  client.ws.send(JSON.stringify(message));
}

function sendError(client, code, message) {
  send(client, { type: 'error', code, message });
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

function pruneRooms() {
  const now = Date.now();
  for (const room of rooms.values()) {
    if (now - room.lastSeenAt > ROOM_TTL_MS || !room.clients.has(room.hostId)) {
      rooms.delete(room.code);
    }
  }
}

const heartbeat = setInterval(() => {
  for (const room of rooms.values()) {
    for (const client of room.clients.values()) {
      if (!client.isAlive) {
        client.ws.terminate();
        continue;
      }
      client.isAlive = false;
      client.ws.ping();
    }
  }
  pruneRooms();
}, HEARTBEAT_MS);

heartbeat.unref?.();

export default server;
