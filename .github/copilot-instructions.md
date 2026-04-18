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

## App framework Usage
- apps are created with the helper function, for instance create_sample_app() usually without any parameters.
- Most of the configuration is done via :setters prefix, for instance `:setters:auto_warp(TRUE)`.
- ALl the app configuration is defined within the `cfg` LEXICON, which is populated in the app helper function.
- For each configuration parameter defined in the `cfg` LEXICON, a corresponding setter function is automatically generated with the same name as the parameter. For instance, if `auto_warp` is defined in the `cfg` LEXICON, then a setter function `auto_warp(value)` will be generated that sets the value of `auto_warp` in the `cfg` LEXICON to the provided value and returns the app object itself to allow for chaining.
- Besides a direct setter for each parameter there could be also defined custom setters, which are defined in the `custom_setters` LEXICON. For instance, if there is a custom setter `target_body(body_name)` defined in the `custom_setters` LEXICON, then a setter function `target_body(body_name)` will be generated that does some custom initialization and returns the app object itself to allow for chaining.
- :setters object also has :app() prefix that returns the app object itself to allow invoking app metods like :run() after setting the configuration parameters. For instance, `:setters:auto_warp(TRUE):app():run()` will set the `auto_warp` configuration parameter to TRUE and then run the app.