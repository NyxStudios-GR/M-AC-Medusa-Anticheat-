# M-AC / Medusa Anticheat — TPZ RedM staging baseline

This is a **staging baseline**, not complete exploit protection. Start in observation mode (`Config.ObserveOnly = true`). Invalid protected actions are rejected even in observation mode; scores do not automatically warn, kick or ban.

## Repository audit


Critical corrections:

- TPZ adapter uses `getCoreAPI()`, `GetPlayer(src).loaded()`, `getAccount(0)` and `getJob()`. Unloaded/unavailable players return nil instead of a fictional zero balance. Checked against TPZ Core commit `577078fb9419623140c31769459ea1034dbad0f3`.
- Protected actions require explicit server registration, validator and callback. There are no default money/item/job actions. Tokens are session markers, not authorization or protection against an injected client. Direct legacy network handlers remain reachable until their owning resources are changed.
- Heartbeats never trust supplied coordinates/hit counts. Movement, if enabled, samples server entity coordinates. Combat probing is disabled; the original probe counted damage received, not authoritative attacks.
- RCON no longer charges every player or cancels operator commands. Commands must be instrumented by their owning server resource through `MarkCommand`.
- Token requests are throttled, an unexpired token is reused, clients request renewal, expired tokens are rejected without punishment, and disconnect/resource-stop state is cleaned up.
- Protected ingress and detector windows are bounded; repeated flags have a score/log cooldown.
- Automatic enforcement defaults off. Movement, combat and balance-delta detectors default off until integrated/tuned.
- Bans persist to a server file before dropping a player; only stable license/Steam IDs are stored, never IP. Persistence failure refuses the ban. Malformed ban storage stops startup.
- Logs retain multiple records and rotate at a configured size. Webhook and admin configuration are server-only. Discord bodies suppress mentions.

## Install

Copy `m-ac/` as a resource named `m-ac` and start after `tpz_core`:

```cfg
ensure tpz_core
ensure m-ac
# Optional secret. Use set, not setr.
set m_ac_webhook ""
```

Keep observation enabled initially. Resource manifest includes the RedM prerelease acknowledgement and TPZ dependency. Writable resource storage is required for bans/logs. Back up the ban file. For unban, stop `m-ac`, remove the relevant stable identifiers from its JSON file, then restart. This storage is separate from TPZ's own ban system.

## Integrate an action

Allowlist the owning resource in `Config.TrustedResources`. In its **server** startup code:

```lua
local registered = exports['m-ac']:RegisterProtectedAction(
    'my_shop:buy',
    function(src, payload)
        if type(payload.productId) ~= 'string' then
            return false
        end

        -- Implement authoritative product lookup, price, stock, balance,
        -- distance, character/session state, cooldown and permissions here.
        -- Reject arbitrary amounts, target IDs and client-supplied prices.
        return false -- Deny until the actual shop validation is implemented.
    end,
    function(src, payload)
        -- Commit the validated purchase atomically here.
        -- Recheck state under a transaction/lock if operations can yield.
    end
)

if not registered then
    error('M-AC action registration failed')
end
```

Clients call `exports['m-ac']:ProtectedTrigger('my_shop:buy', payload)`. False means no token was available and **nothing was sent**. There is no automatic retry/acknowledgement. A valid token can be reused, so each action must enforce cooldown/idempotency and server authorization. Do not automatically retry purchases. Avoid yielding between validation and mutation without transaction/locking and session revalidation.

Remove/disable the original unguarded handler in the owning resource. Merely registering another handler or adding an event name does not secure a TPZ resource. Actions are removed when their owning resource stops; re-register after restarting `m-ac` (restart dependent resources too).

Server commands may call `exports['m-ac']:MarkCommand(src)` inside their authenticated command callback. M-AC does not globally intercept commands/events.

## Required live tests, in priority order

1. **P0 — Boot and player lifecycle:** pin your installed TPZ version; start resources, select a character, verify money/job reads, reconnect, restart `m-ac` with players online, and stop/restart TPZ. No errors or sanctions; unavailable characters must not appear as zero-money characters.
2. **P0 — One real protected action:** migrate one low-risk shop action with server authorization and atomic handling. Verify wrong/expired/missing token, unknown action, malformed data, negative/huge amounts, spoofed target and duplicate requests cannot change money/items. Verify the old direct event cannot still grant anything. A legitimate action must execute exactly once. The generic wrapper alone cannot prove this.
3. **P0 — Session/abuse behavior:** test beyond the 180-second token TTL, disconnect/source reuse, owning-resource restart and `m-ac` restart. Test bounded event/token floods while observing server CPU, network, console and disk. No automatic replay of transactions.
4. **P0 — Durable sanctions and logs:** use disposable accounts. Check multiple JSONL lines, rotation, Discord delivery, file write failure, ban/reconnect/restart/unban and corrupted ban file behavior. TPZ connection deferrals must coexist. Enable enforcement only for this controlled test, then restore observation.
5. **P1 — False-positive calibration:** horses, wagons, trains, respawn, fast travel, admin teleports, routing buckets, lag and character changes. Keep movement disabled until server-side exemptions and grace periods are implemented for your actual resources. Check legitimate payouts before enabling economy heuristics. An increase in balance is not proof of an exploit.
6. **P1 — Native/entity coverage:** confirm `entityCreating`/ownership behavior on your RedM artifact and OneSync configuration with legitimate NPC/horse/wagon spawning. Current entity detection records scores; it does not cancel entity creation. Test admin allowlist with normal and admin accounts. Combat detection is not implemented as authoritative weapon/damage validation and must remain disabled.

No heartbeat timeout/client-resource-stop enforcement, automatic legacy TPZ patching, economy ledger, teleport exemption API or authoritative combat enforcement is claimed. These must be designed around your actual server resources before enabling the corresponding features in production.

## Local validation

```sh
python3 tests/run.py
```

Requires the Lua 5.4 shared library. The runner uses the real Lua loader for syntax checking and mocked Cfx/TPZ APIs for behavioral regressions. This is **not** live RedM validation, and does not execute `luac`. If `luac5.4` is installed, additionally run it separately on every Lua file. Do not substitute a file listing for syntax/runtime tests.
