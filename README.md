# M-AC (Medusa Anticheat)

M-AC is a modular anticheat and anti-exploit resource for **RedM** servers running on **TPZ Core**.

> Repository target: `tpz_core` ecosystem (`https://github.com/TPZ-CORE/tpz_core`)

## Features

- Multi-layer detection model (client, server, behavior, session integrity)
- Tokenized event authentication to reduce event spoofing
- Server-authoritative economy/action sanity checks
- Entity and spam protections (spawn flood, event flood, command flood)
- Weapon and combat anomaly detection (rate-of-fire and impossible damage patterns)
- Teleport / noclip / speed-hack heuristics
- Permission-aware admin bypass with strict allowlist
- Progressive punishments (warn → kick → ban)
- Structured log pipeline (console + JSONL + webhook-ready)
- Runtime adaptive thresholds per risk profile

## Resource Layout

```text
m-ac/
├── fxmanifest.lua
├── config.lua
├── shared/
│   ├── constants.lua
│   └── utils.lua
├── server/
│   ├── main.lua
│   ├── event_guard.lua
│   ├── detection_engine.lua
│   ├── punishment.lua
│   └── adapters/
│       └── tpz_core.lua
└── client/
    ├── main.lua
    └── probes.lua
```

## Install

1. Copy `m-ac` to your RedM resources folder.
2. Ensure `tpz_core` starts before `m-ac`.
3. Add to `server.cfg`:

```cfg
ensure tpz_core
ensure m-ac
```

4. Edit `m-ac/config.lua` for your policy and webhooks.

## Notes

- Anticheat systems must be tuned to your server gameplay.
- Keep thresholds conservative first, then harden.
- M-AC is intentionally modular so you can plug TPZ-specific validations quickly.
