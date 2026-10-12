# Multiplayer game services

Read this when the user requests online multiplayer. Single-player templates stay offline by default.
This page owns the shared service workflow; the selected game's README owns its messages, rules and tests.
Project-local `docs/game-multiplayer.md` and README-backed Skills may contain older template snapshots.
For cloud-computer selection, updates and responsive controls, follow this installed Skill page over those snapshots.
A cloud computer selected in Multiplayer is a deployment target, not an already running game server.

## Read the runnable source before adapting

For an existing offline game gaining multiplayer, keep its project and gameplay. Use the
**Multiplayer reference source** directory returned by init/attach; it identifies the current
installed Generic Multiplayer starter even when this project was initialized from another genre.
Read `scripts/net/connection.gd`, `scripts/main.gd`, `scripts/net/protocol.gd` and
`server/authoritative_server.mjs` there before writing the integration. A gameplay guide describes
the contract; it does not replace reading these implementations. Never reinitialize the project or
edit the installed reference. Copy the connection component into the game's own source and adapt
the protocol/room adapter, server rules and UI together. Preserve an existing working networking
implementation instead of replacing it just because the installed reference is newer.

The Generic Multiplayer guide returned by init/attach (or the reference directory's README),
section **Reusable connection component**, owns the API and cancellation/retry behavior.
Read its tests when changing that behavior.

## Read and update the project's cloud computer

The project's saved multiplayer selection is authoritative for its deployment target. Read and update it
through `webdev.config`; the Multiplayer panel uses the same project record. Do not infer the saved
selection from the active execution device, an earlier chat message, or a local file.

When proposing computers, use the built-in `manus-device.list_devices`; show each name, ID and hosting `region_id`,
plus a recognized location (for example Singapore, `asia-southeast1`). Missing `region_id` means unknown;
never infer it from names/IDs. Use the requester's location to suggest nearby regions without claiming
measured latency or a fastest region without measurements. Preserve an explicit selection.

**Existing Game project:** first read the current selection:

```json
{"method":"GET","path":"game/multiplayer"}
```

A successful response contains `data.resourceId`, `data.selection.pcId`, `data.selection.revision`, and
`data.selectedServer` (safe computer details/status, or null). `pcId: null` means no computer is selected.
A non-null `pcId` with a null/unavailable server means the saved target needs attention, not that the
selection has been cleared. Computer readiness does not prove that the game service is running.

If the user has not requested a change, reuse the saved computer. If there is no selection, discover
available cloud computers with `manus-device.list_devices` and ask which one to use. If the user has
already explicitly selected a computer, do not ask them to repeat the choice in the panel. This includes
a Multiplayer button message, a natural-language choice, or a device ID inserted by **Switch to another
device** when the message/context explicitly asks to use it for this game's multiplayer service.
A request merely to switch execution devices does not change the project's multiplayer selection.

Save a new choice with the exact `pcId` and the revision just read. For example, **only if GET returned
revision 3**, call:

```json
{"method":"PUT","path":"game/multiplayer","body":{"pcId":"USER_SELECTED_COMPUTER_ID","expectedRevision":3}}
```

Replace the example ID and revision with the real values. The successful response contains
`data.selection` with the new revision. Report the project selection as saved only after `ok: true`.
The panel refreshes from the server event; do not make a second UI write. A failed request is not a
successful sync. After a lost response or a 409, GET again: if the value already matches the intended
computer, the selection is saved; otherwise resolve the conflicting choice before writing again.
Never blindly retry with a newer revision to overwrite another selection. For an explicit request to
unlink the computer, GET then PUT `pcId: null` with the current revision. Unlinking or changing selection
does not stop, migrate or delete an existing service or computer.

**No Game project yet:** explain that online multiplayer needs a cloud computer, use `list_devices`
to discover available computers, and confirm the user's choice before initialization. Listing does not
require switching. If none is available, direct the user to
[buy a cloud computer](https://manus.im/app#settings/my-computer/create) and refresh after startup; do not
purchase one for them. After project initialization, immediately GET and PUT the chosen computer into
that project before implementing/deploying multiplayer. Do not initialize just to expose the panel.

These calls require the owner's session attached to a ready Game project. Save the choice while the
project's Addon runtime is available, before switching to the deployment computer. If already elsewhere
and the tool is unavailable, switch back through the normal device tools to the project's development
environment, read/save there, then return to the intended computer. Do not copy credentials or bypass
the device boundary with shell requests. Recheck the selection before deployment; switching back to
the development computer or Sandbox afterward must not overwrite it. A saved selection does not grant
remote-control authorization: complete the normal device access flow separately.

## Cloud computer unavailable or device switch fails

If connecting or switching to the selected cloud computer fails, times out or becomes unresponsive,
use the built-in MCP tools directly: call `manus-device.list_devices`, match `device_id` to the
project's saved `pcId`, then call `manus-device.get_environment_status` with that record's exact
`environment_id`. Both calls work from the current environment without switching to the failing
computer. Read CPU and memory from the status response, not the device list. If these tools are not
exposed or the target is unavailable, report the diagnostic limitation; do not invent load readings.

Check metric freshness. CPU utilization is a ratio from 0 to 1; memory usage and capacity are bytes.
Cloud-provider sampling time may be unknown: describe those readings as possibly outdated and overload
as a possible cause. Missing or stale metrics establish neither healthy load nor exhaustion.
If the computer remains unresponsive and reported CPU is near 1 (100%) or memory is near capacity,
explain the readings and ask the user to open Manus Settings and reset that cloud computer. Warn that
reset interrupts running work; leave it to the user and stop deployment and repeated switch attempts.
A single slow command or high reading on a responsive computer does not justify a reset recommendation.
After the user resets it, list devices again, query the target's status and check the service before
resuming deployment or claiming recovery. If diagnostics do not support exhaustion, investigate device
availability or access errors instead; a failed switch alone does not prove overload.

## Client and server responsibilities

Keep the editable Godot game in its authorized project. Use the installed Game workflow for Preview,
asset hydration, release preparation and checkpoint publication. Keep the matching service source and
dependency lockfile with the project. Static Web publication does not start a long-running WebSocket server.

For the computer saved on the project, check its device identity, online
status, authorized workspace and available runtime through the current device tools. Selection does not
grant cross-device access or authorize purchasing another computer. Complete the normal device access
flow and stop at a real permission denial; do not change global access settings to make deployment work.
Finish or stop an owned foreground Preview operation before switching devices when the tool requires it.

The server owns rooms, seats, simulation, legal actions, scores and round transitions. Clients send bounded
input/actions and use accepted snapshots as authority. Local presentation follows the responsive-controls
recipe below; client coordinates, elapsed time and scores are not authority.
Validate message type, shape, size, rate, room membership and the socket's current seat before mutation.
Use a protocol/build identifier and increasing snapshot or action revisions; reject incompatible clients,
ignore stale snapshots and make retried game actions idempotent where their semantics require it.

Define room capacity, spectators, disconnect grace, expiry and restart behavior. A resume credential is
server-issued, room-scoped and secret. Keep it out of invitation links, logs and source. Use tab-scoped
browser storage so two independent players do not accidentally share a seat. A replaced socket must lose
input authority immediately. Lost storage, an expired room and a restarted in-memory server need explicit
recovery UI. Do not promise durable rooms without implementing storage and recovery.

Bound active rooms, connections, spectators, queued outbound bytes and incoming messages. Add heartbeat
cleanup for dead connections. Room codes are discoverable invitations, not private-room authentication;
private or account-based play needs the game's own authentication policy. State these limits honestly.

## Server runtime selection

Prefer a standalone socket server without a Godot dependency, normally Node.js with `ws`, following
an existing matching template's service and protocol. Here "socket server" still owns authoritative
rules, simulation and validation; it is not merely a relay for client-supplied positions or scores.
Keep Godot on the client for input and presentation. This default also applies when adding multiplayer
to Generic or another initially offline template. Do not choose server-side Godot just because the
client or shared offline gameplay code uses GDScript.

Consider headless Godot only when reusing concrete engine-dependent physics, navigation or scene
simulation provides a material benefit that the standalone service cannot reasonably preserve. Record
that benefit, the deployment budget and the tradeoff in the project plan before choosing it. Simple
room coordination, grid rules, timers and turn-based actions do not by themselves justify the engine.

Explain the resource risk when proposing this exception: `--headless` removes display rendering,
not engine initialization, simulation or worker threads. Unbounded ticks, threads or loaded resources
can contend with existing services and the computer's control process; memory exhaustion can terminate
processes and CPU pressure can make control unresponsive. More RAM alone does not establish safety.
Do not present a successful short check as proof of sustained capacity or attribute a disconnect to
resource exhaustion without resource/process evidence.

Prepare and validate any dedicated-server export in the development computer/Sandbox, stripping
unneeded client resources. Do not run editor imports, client builds or client visual tests on the
cloud deployment computer. Inspect its available resources and existing services first; use bounded
smoke checks and explicit CPU, memory, thread/process and room limits appropriate to that machine,
leaving capacity for the control channel. Verify representative concurrent play and control responsiveness
before making capacity claims. Preserve existing services and diagnose failed checks before retrying.

## Responsive controls with minimal client logic

When creating or adapting an online game, provide immediate local feedback. Do not wait for a server
round trip before showing the player's movement or action start. Use **local anticipation with smooth
correction** as the default for simple movement such as Pong paddles or a freely moving character.
Keep authoritative state separate from the locally displayed state. This recipe needs only the latest
snapshot and a local movement state, not an input history or a whole-world rollback system.

1. **Move locally on input.** Each local simulation step, advance only the owned object's anticipated
   position with the current input, matching the server's speed and simple movement bounds. Render it
   immediately. Send bounded input on the network schedule independently; neither loop waits for a reply.
2. **Keep the server in charge.** The server still simulates and validates input. Keep remote players
   and shared objects on the existing snapshot presentation path. Play local action-start animation or
   sound immediately, but confirm damage, pickups, scores and round results from the server. For cards
   or turn-based actions, show a pending placement/animation and restore it on rejection; do not guess
   hidden information or randomly determined results. Avoid replaying the same effect on confirmation.
3. **Correct toward a comparable time.** A snapshot describes the past. For simple free movement,
   project its authoritative position forward using its authoritative velocity and estimated snapshot
   age, capped initially at 150 ms, and clamp to the same movement bounds. Estimate age using a
   server/client clock mapping, or half a smoothed measured RTT plus time since local receipt; never
   subtract unrelated clocks. Use this target for correction, not the raw old position. Add velocity
   and timing support to both protocol ends when absent; these are requirements for an adaptation,
   not fields guaranteed by every starter. Do not extrapolate through unknown collisions or transitions.
4. **Blend small errors; reset exceptional states.** After applying current local input, gently move
   toward the correction target with a frame-rate-independent weight such as `1 - exp(-dt / 0.10)`.
   Start with a small dead zone relative to object size so tiny errors do not cause jitter. Apply an
   explicit teleport, respawn, rejected movement or large divergence immediately and clear the old
   anticipation. Ignore stale snapshots. Stop anticipation on disconnect, loss of seat or a non-playing
   phase; reset from a fresh snapshot after reconnect. Bound how long prediction continues without
   fresh snapshots and show reconnecting instead of allowing indefinite local movement.

For Pong, anticipate **only your own paddle**; leave the opponent, ball collisions and scoring with
the authoritative service and snapshot presentation. The current Generic Multiplayer starter implements this in
`scripts/game/local_paddle.gd`. Older snapshot-only Pong projects smooth all objects toward received snapshots
and require a client/service adaptation; changing a smoothing constant alone is insufficient. A pending
direction-change sequence can suppress older corrections briefly without an input history; bound that
wait so a rejected input cannot prevent eventual correction.

This is an approximate latency-hiding approach: rapid reversals, collisions and high latency can still
produce visible corrections. Tune it for the requested game rather than promising exact prediction.
If the requested gameplay needs precise collision-heavy movement or competitive timing, use input
sequence acknowledgements and replay of unacknowledged inputs, or an established networking solution,
instead of expanding this approximation into an ad hoc rollback engine.

Acceptance: use two clients with simulated 100–200 ms RTT and jitter in an isolated test. Local movement
must start on the next local update without waiting for a snapshot, continue smoothly while held, and
stop/reverse promptly. Check small correction, large reset, rejected action and reconnect; after input
stops, the client must converge to the server. Scores must agree and effects must not fire twice.
Use the existing native/protocol test path and targeted user Web acceptance; this does not add a routine
browser-automation requirement. A localhost-only check does not establish responsive internet play.

## Configure the public connection

For Addon Game projects, use the existing project `multiplayer/config.json` and same-origin
`multiplayer/bootstrap.json` discovery contract. The field `signalingUrl` also names a dedicated
authoritative WebSocket server; it does not require peer-to-peer networking. A project configuration is:

```json
{"build":"GAME_PROTOCOL_VERSION","signalingUrl":"wss://VERIFIED_GAME_HOST/ws","iceTransportPolicy":"all"}
```

Replace both placeholders with the game's actual build identifier and verified service endpoint. `all`
is the existing descriptor default; direct WebSocket games do not use ICE/TURN. Never add TURN secrets,
device credentials, resume tokens or private service keys to this public file. Use the same build in
the service and client. Addon Preview and release preparation generate the discovery descriptor; do not
hand-edit generated `site/`, `dist/`, a saved checkpoint or the installed runtime to change it.

Resolve the descriptor relative to the actual game page, preserving its preview ingress prefix. Do not
assume the host-root `/multiplayer/` is the project origin. Keep the WebSocket endpoint operator-owned:
an invitation may select a room but must not override the endpoint. HTTPS pages require WSS. Loopback
WS is only for explicitly local tests, not a remotely opened Preview or published client. Missing service
configuration must show an actionable unavailable/retry state, never simulate a successful online match.

Native tests have no browser origin: supply the explicit test endpoint through the template's documented
native configuration. A shell-only override does not configure an Addon publication. Record which client
origin and service endpoint were actually tested.

## Prepare and run the service

Inspect the chosen computer before changing it: operating system, user/workspace, Node or other runtime,
occupied ports, existing services, proxy configuration and the current deployment directory. Use a new,
project-specific directory and service name. Do not overwrite an unrelated service or reinstall a working
proxy. Choose an available application port and bind loopback when an existing local reverse proxy owns
public ingress. A remote/public bind requires the intended authenticated/TLS network setup.

Freeze the server source, manifest and lockfile together. Build the Godot client on the development
computer/Sandbox, not by silently moving the whole development workflow to the cloud computer. Transfer
only the intended deployment files, without `.env`, personal data or unrelated projects. Generate and
verify SHA-256 checksums before and after transfer. Preserve the package manager and install from its
lockfile, for example `pnpm install --frozen-lockfile --prod` for a pnpm service or `npm ci --omit=dev`
for a package-lock service. Do not discard lockfiles to get a different dependency graph installed.

Run the server once on its selected port and inspect `/healthz` (or its actual documented health route)
before making it persistent. Use the OS's existing service manager. On a Linux computer with a working
user systemd manager, install a project-specific unit under `~/.config/systemd/user/` with the verified
working directory, absolute executable path, port and restart policy. Do not hardcode another user's UID
or a sample machine's paths. Use `systemctl --user daemon-reload`, then enable/start the exact new unit.
Check status and `journalctl --user -u UNIT`; scope restart/stop commands to that unit.

An isolated device terminal may not see the host's user D-Bus. Verify the current UID and the existing
`/run/user/UID/bus`, and use the device tool's normally approved host-access mechanism if needed. Set
`XDG_RUNTIME_DIR` and `DBUS_SESSION_BUS_ADDRESS` for that verified user manager only. This does not
require becoming root or disabling the sandbox. If host access or a user manager is unavailable, report
the limitation and use an explicitly supported service manager; do not claim `nohup` survives reboot.
User-unit boot persistence also depends on the machine's user-manager/linger configuration: verify it
rather than assuming that `enabled` alone proves unattended startup.

## HTTPS, WSS and client publication

Reuse the computer's existing verified HTTPS reverse proxy where available. Check that it forwards the
actual WebSocket `/ws` upgrade, preserves the query string, permits a long-lived connection and sends
health traffic to the correct upstream. Inspect existing routing before proposing a change. A healthy
loopback port does not prove a public endpoint; a public HTTP health check does not prove WSS upgrade.

The normal Addon arrangement serves the client from its published static origin and the game service
from the chosen cloud computer's WSS origin. Configure the service's browser-origin policy for the actual
client origins, including the current Preview only when intentionally testing it. WebSocket Origin checks
complement room authentication; generic HTTP CORS headers do not authorize a WebSocket connection.

If the user explicitly chooses a combined deployment, the same server can also serve the frozen Godot
Web output. Transfer the complete release and every referenced content-hashed WASM/PCK asset, preserving
their paths and hashes. Use `application/wasm` for WASM and the correct JS/JSON content types. Do not copy
only HTML, use an old PCK, or imply this separately hosted site is the Addon's published checkpoint.
Keep private source/config outside the static root and prevent directory traversal and symlink escape.

## Verify, update and troubleshoot

Test in this order: deterministic protocol/simulation checks; two independent clients against an isolated
local server; native Godot import/render and current-source Web export; cloud loopback health; public
HTTPS and WSS; then targeted player acceptance on the actual client origin. Follow the Game workflow's
existing visual/browser acceptance policy rather than adding routine browser automation to every edit.

Verify independent seat assignment and input ownership, matching authoritative scores, a full-room
spectator, disconnect/reconnect within grace, expired credentials, stale messages, and service restart.
Two clients in different rooms must not affect each other. Include malformed/oversized inputs and a
replaced socket attempting to act. Distinguish local protocol success from a publicly playable game.

| Symptom | Check |
| --- | --- |
| Cannot connect or switch to the cloud computer | Follow [device load and reset diagnostics](game-multiplayer.md#cloud-computer-unavailable-or-device-switch-fails) |
| Public 502 | Exact service status, listening port and proxy upstream |
| Healthy HTTP, failed WSS | Upgrade path, TLS, Origin policy and protocol version |
| One player waits | Same room/build/endpoint, second client connected, reserved seats |
| Refresh changes seat | Tab storage availability, resume grace and server restart |
| Scores disagree | Client-side simulation, stale snapshots, room identity |
| Godot fails to load | Current WASM/PCK hashes and paths, MIME and resource/font imports |
| User-service bus error | Verified host user manager, bus path and approved execution context |

For updates, validate the new source first, transfer a new version, verify hashes, switch only this
service and repeat health/WSS checks. Preserve the previous deployable version for rollback. An
in-memory room restart disconnects players and loses scores; drain/announce it as appropriate. Changing
discovery does not migrate live rooms. Never publish a temporary test endpoint as permanent hosting.

Deliver the client URL, service/health endpoints, deployment version, persistence/restart behavior and
the checks actually completed. Keep infrastructure detail in development guidance, not player menus.
