# Online Multiplayer Plan

## Recommendation

Use the current host-authoritative game model and replace the LAN-only ENet
transport with an online relay for browser play:

1. Godot host creates an online room.
2. The relay assigns a 4-letter lobby code.
3. Joining clients connect with that code.
4. Clients send small action requests to the host.
5. The host validates the action against `GameState`, mutates the game, and
   broadcasts snapshots back through the relay.

This keeps rules authority in the existing Godot code and keeps packets small:
only plays, buys, choices, end-turn requests, and state snapshots cross the
wire.

## Shipped Prototype Path

- `api/relay.js` is a standalone Node HTTP polling relay with in-memory 4-letter
  rooms. It binds `0.0.0.0:$PORT` and must run as exactly one always-on instance
  (no serverless, no autoscaling), because all room state lives in that one
  process.
- `scripts/ui/main_ui.gd` now has an online HTTP polling transport alongside the
  existing local ENet transport. Every build targets a fixed relay URL
  (`ONLINE_RELAY_DEFAULT_URL`, currently the Render deployment), overridable via
  the `CONQUEST_CARTES_RELAY_URL` environment variable or `online_relay_url_override`
  for tests. The relay sets permissive CORS so the cross-origin isolated web
  build can reach it.
- The relay is deployed on its own always-on host (currently Render). The GitHub
  deploy workflow publishes only the static web build to Vercel (with COOP/COEP
  headers); it does not bundle or deploy the relay.

This is enough for a production smoke test, but it is still a prototype relay:
rooms are held in memory in a single process, so any restart or redeploy drops
open lobbies, and the service cannot scale horizontally.

## Production-Hardening Path

For reliably low-ping public multiplayer, move the relay state to a realtime
service that guarantees room affinity:

- Best fit: Cloudflare Durable Objects or PartyKit, because each room code maps
  naturally to one durable room object near the users.
- Strong managed alternative: Ably or Pusher Channels, using the same Godot JSON
  protocol but replacing the relay endpoint.
- Single-host hardening: keep the standalone Node relay but add persistent room
  presence (e.g. Redis), client reconnect/resume, and a process manager or
  managed always-on runtime. This is workable, but more moving pieces than a
  room-native realtime backend.

## Prompt For The Next Pass

Implement production-grade online multiplayer for this Godot 4.7 web card game.
Keep the host-authoritative architecture in `scripts/ui/main_ui.gd`; clients
must only send action requests, and the host must remain the only process that
mutates `GameState`. Preserve local ENet multiplayer. For online play, use
4-letter uppercase lobby codes, realtime transport, player assignment, host
snapshots, client reconnect handling, room-full errors, host-disconnect errors,
and lobby-code copy/join UI. If keeping the standalone Node relay, make its room
state durable (e.g. Redis-backed presence and pub/sub) and handle reconnects. If
moving to Durable Objects or PartyKit, keep the same JSON message schema already
used by `api/relay.js` so the Godot client changes stay small. Update README,
deployment workflow, and smoke tests.
