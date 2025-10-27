You are building a CLI utility (run via `uv run`) that loads a single VOLO-App manifest (see `DS1120-PD_app.yaml`) and auto-generates a Textual TUI showing the app metadata plus register widgets.

Context to keep in-frame:
- Validation models live in `models/volo-models/app_register.py` and `models/volo-models/volo_app.py`. Use them to parse and validate YAML input before rendering.
- Current register types (RegisterType Enum): `counter_8bit`, `percent`, `button`.
- Sample manifest registers (CR20-CR30) include buttons (`Armed`, `Force Fire`, `Reset FSM`) and multiple counters (e.g., `Timing Control`, `Intensity Low`).

UI requirements:
- App name acts as the window title/header; show version/author/tags/bitstream metadata near the top.
- Registers render inside a `DataTable` with columns `CR`, `Name`, `Type`, `Default`, `Description`.
- Each row also spawns an associated widget region: `percent` → `ProgressBar`, `button` → `Button`, `counter_8bit` → labeled read-only `Input`/`TextInput`.
- Register values are read-only snapshots of the manifest defaults, but every generated interactive widget must wire up a stub handler that a human can flesh out later.
- Table must support row selection, sorting (by CR), and basic filtering (e.g., type/name substring).

Operational notes:
- CLI accepts a manifest path argument, loads it once at startup, and does not support hot swapping.
- Keep layout simple: app header, metadata panel, register table + widget column, optional footer for status messages.
- No color-coding or custom themes by default.
