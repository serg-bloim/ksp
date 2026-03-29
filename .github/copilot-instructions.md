# GitHub Copilot Instructions

## Project Overview

This is a **Kerbal Space Program (KSP)** automation project written in **kOS Script** (`.ks` files).
[kOS](https://ksp-kos.github.io/KOS/) is a KSP mod that adds a scriptable onboard computer to rockets and spacecraft.

## Language & Runtime

- **Language:** kOS Script (KSScript) — a custom scripting language for the kOS mod.
- **File extension:** `.ks`
- **Key concepts:** `LOCK`, `SET`, `UNTIL`, `WHEN/THEN`, `ON`, `LEXICON`, `LIST`, `DELEGATE` (`@` suffix for function references), `RUNONCEPATH`, `PARAMETER`, `GLOBAL`, `LOCAL`.
- Scripts run on a virtual CPU aboard the ship. CPU power is limited (instructions-per-update budget).
- `0://` refers to the kOS "archive" (persistent storage), `1://` refers to local vessel disk.

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `app/`    | High-level mission apps (rendezvous, landing, maneuvers, orbital, etc.) |
| `util/`   | Reusable utility libraries (math, orbital mechanics, logging, app framework, etc.) |
| `bin/`    | Standalone executable scripts (autopilot, circularise, descent, flight log, etc.) |
| `boot/`   | Boot scripts that auto-run when a vessel is loaded |
| `test/`   | Integration/scenario test scripts |
| `unittest/` | Unit tests for individual functions |
| `ui/`     | In-game GUI utilities |
| `ap-ui/`  | Autopilot UI screens |
| `archive/` | Unused / archived code |

## Architecture & Patterns

- **App framework (`util/app.ks`):** Apps are created with `create_app(NAME, run_func, cfg, custom_setters)`. Each app has a `cfg` LEXICON for configuration and auto-generated fluent `setters` for chaining (e.g., `:setters:auto_warp(TRUE):app():run()`).
- **Functional utilities (`util/func.ks`):** Provides higher-order functions (`map`, `descend`, `descend1d`) and a gradient-descent optimizer used for orbital calculations.
- **Logging (`util/log.ks`):** Apps use `app:log(msg)` for structured output. Use `create_logger(app)` to attach a logger.
- **Orbital math (`util/orb.ks`, `util/maneuvers.ks`):** Contains helpers for orbit normal vectors, transfer nodes, Hohmann transfers, and plane changes.
- **Dependencies:** Files declare dependencies via `RUNONCEPATH("0://path/to/file.ks")` at the top.

## Coding Conventions

- Function names use `snake_case`.
- App factory functions are prefixed `create_` (e.g., `create_app_randevous`).
- Configuration keys in a `cfg` LEXICON use `snake_case`.
- Use `LOCAL` for block-scoped variables and `GLOBAL` sparingly (mostly for exit codes like `EXIT_CODE`, `EXIT_ITERS`).
- Prefer delegate references (`func@`) over inline anonymous functions when passing callbacks.
- All scripts intended for reuse should be wrapped with `RUNONCEPATH` guards via the `0://` archive path.

## Domain Knowledge

- **KSP orbital mechanics:** Apoapsis, periapsis, inclination, true anomaly, argument of periapsis, longitude of ascending node, semi-major axis, orbital period, Δv (delta-v).
- **Maneuver nodes:** Created with `NODE(time, radial, normal, prograde)` and added with `ADD`.
- **Staging:** Managed via `STAGE` command; fuel depletion detected by monitoring resources.
- **RCS / SAS:** Reaction Control System and Stability Assist System for attitude control.
- **Warp:** `SET WARP TO n` or `WARPTO(time)` to time-accelerate to a future moment.
- **Bodies:** Kerbin (home planet), Mun (moon of Kerbin), Minmus, Duna, etc.

