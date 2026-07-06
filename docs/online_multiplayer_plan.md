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

- `api/relay.js` is a Vercel HTTP polling relay with in-memory 4-letter rooms.
- `scripts/ui/main_ui.gd` now has an online HTTP polling transport alongside the
  existing local ENet transport.
- The GitHub deploy workflow copies `api/relay.js` and `package.json` into the
  generated `web/` deployment bundle so `/api/relay` exists on Vercel.

This should be enough for a production smoke test on Vercel, but it is still a
prototype relay because Vercel can move HTTP requests to different function
instances and in-memory rooms disappear on cold starts.

## Production-Hardening Path

For reliably low-ping public multiplayer, move the relay state to a realtime
service that guarantees room affinity:

- Best fit: Cloudflare Durable Objects or PartyKit, because each room code maps
  naturally to one durable room object near the users.
- Strong managed alternative: Ably or Pusher Channels, using the same Godot JSON
  protocol but replacing `/api/relay`.
- Vercel-only hardening: add Redis-backed room presence and pub/sub, client
  reconnects, and deployment-aware resume. This is workable, but more moving
  pieces than a room-native realtime backend.

## Prompt For The Next Pass

Implement production-grade online multiplayer for this Godot 4.7 web card game.
Keep the host-authoritative architecture in `scripts/ui/main_ui.gd`; clients
must only send action requests, and the host must remain the only process that
mutates `GameState`. Preserve local ENet multiplayer. For online play, use
4-letter uppercase lobby codes, realtime transport, player assignment, host
snapshots, client reconnect handling, room-full errors, host-disconnect errors,
and lobby-code copy/join UI. If staying on Vercel, make `/api/relay` durable
across function instances with Redis/pubsub and handle reconnects. If moving to
Durable Objects or PartyKit, keep the same
JSON message schema already used by `api/relay.js` so the Godot client changes
stay small. Update README, deployment workflow, and smoke tests.
