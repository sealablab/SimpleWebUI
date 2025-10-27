# P2 – Implementation Guide

This document describes how to implement the VoloApp textual UI generator end‑to‑end without further clarification.

## 1. Goals
- Load a single VOLO-App manifest (YAML) at startup, validate it with the existing Pydantic models, and present the results in a Textual-based TUI.
- Provide a read-only register summary inside a sortable/filterable `DataTable` plus auto-generated widget previews per register type (`ProgressBar`, `Button`, read-only `Input`).
- Expose app metadata (name/version/author/tags/bitstream path) prominently, with the app name acting as the window title.
- Stub out event handlers for interactive widgets; humans will later flesh out the logic.
- Distribute/run via `uv run python -m simpleui <manifest.yaml>` (exact module/package name TBD, but must be wired through `uv`).

## 2. Key Resources
- Manifest example: `DS1120-PD_app.yaml`.
- Pydantic models: `models/volo-models/app_register.py` (`AppRegister`, `RegisterType`) and `models/volo-models/volo_app.py` (`VoloApp`).
- Architectural context: `VOLO_APP_DESIGN.md`.

## 3. High-Level Architecture
1. **CLI entrypoint** (Typer or plain argparse) accepts `--manifest PATH`.
2. **Loader module**:
   - Parse YAML via `yaml.safe_load`.
   - Instantiate `VoloApp` using parsed data to leverage validation (range checks, CR uniqueness, etc.).
   - Convert to internal DTOs for the TUI (precompute signal names, bit ranges, etc. if needed).
3. **Textual App**:
   - `App` subclass sets `TITLE` (app name) and `CSS_PATH` (optional; keep default styling minimal).
   - Layout suggestion: `Header` (with app name), `Footer`, `Horizontal` split where left contains metadata panel, right contains the registers table + widget column.
   - Compose:
     - Metadata view: `Static` widgets or `ListView` summarizing version, author, tags, bitstream path, buffer path.
     - Register view container: `DataTable` at top, `ContentSwitcher` or vertical list of generated widgets below.
   - Provide filter input (Textual `Input`) above the table; hook `on_input_changed` to call `table.show_row` logic based on substring match of name/type/CR.
   - Sorting: default ascending by `cr_number`. Enable `DataTable.sort` triggered when header clicked or via dedicated `on_button_pressed`.
4. **Widget generation**:
   - Iterate registers and instantiate:
     - `counter_8bit`: `Input` with `placeholder`/`value` showing default, `disabled=True`.
     - `percent`: `ProgressBar` with `total=100`, `progress=default_value`.
     - `button`: Textual `Button` labeled with register name; attach stub `on_button_pressed`.
   - Store mapping `register_id -> widget` for event routing/logging.
5. **Handlers / Logging**:
   - Implement stub methods (e.g., `def handle_button_press(self, register: AppRegister) -> None:`) that currently just log via `rich.console` or `loguru`.
   - Provide docstrings / TODO comments guiding future developers where to integrate actual device calls.

## 4. Implementation Steps
1. **Project wiring**
   - Add package (e.g., `simpleui/` with `__init__.py`, `cli.py`, `tui.py`, `data.py`).
   - Configure `pyproject.toml` `scripts`/`[project.scripts]` entry: `"volo-simpleui" = "simpleui.cli:app"` (Typer) or similar so `uv run volo-simpleui ...` works.
2. **CLI** (`simpleui/cli.py`)
   - Use Typer with command `main(manifest: Path)`.
   - Inside command: load YAML, instantiate `VoloApp`, pass to `run_tui(app_model)`.
   - Catch validation errors and print friendly messages.
3. **Data loader** (`simpleui/data.py`)
   - Function `load_app(Path) -> VoloApp`.
   - Utility `build_table_rows(app: VoloApp) -> list[RegisterRow]` (dataclass containing CR, name, type, default, description).
4. **Textual App** (`simpleui/tui.py`)
   - Subclass `App`.
   - Implement `on_mount` to populate metadata panel and fill `DataTable`.
   - Add `Input` for filter; connect to `on_input_changed`.
   - Use `DataTable.add_column` for `["CR", "Name", "Type", "Default", "Description"]`.
   - `DataTable.add_row` with stringified values; store row IDs keyed by register signal name for filtering/selection.
   - Create `ScrollView` under the table hosting widget panel; for each register add a container with label + widget; wire stub handlers.
5. **Sorting**
   - Either enable built-in column sorting (Textual ≥ 0.35) or provide custom `sort_rows(key="CR")` that reorders data table + widget panel simultaneously.
6. **Filtering**
   - On filter input change, convert text to lowercase and call `table.show_row(row_key, matches)` plus toggle widget containers accordingly.
7. **Handler stubs**
   - Buttons: `on_button_pressed(self, event: Button.Pressed)` -> log `event.button.id`.
   - Progress bars & read-only inputs: provide stub methods like `def on_counter_inspect(self, register_id: str) -> None` triggered when row is selected.
8. **Testing / Validation**
   - Add unit tests for `load_app` and table row builders (pytest). Mock manifest path using fixture pointing to `DS1120-PD_app.yaml`.
   - Optional snapshot test verifying table rows list matches expectation for sample manifest.
   - Manual run: `uv run volo-simpleui DS1120-PD_app.yaml`.

## 5. Extensibility Hooks
- Keep register-to-widget mapping in a dedicated registry/dict so adding new types later only requires extending the mapping.
- Centralize handler stubs in one class to ensure future logic can tap into them easily.
- Consider separating presentation data (`RegisterViewModel`) from Pydantic models to avoid coupling to validation internals.

## 6. Deliverables Checklist
- [ ] `simpleui` package with CLI, loader, and Textual app modules.
- [ ] CLI documented in README or `--help`.
- [ ] Table + widgets honor selection, sorting, filtering.
- [ ] Progress bars, buttons, and read-only inputs match register types.
- [ ] Stub handlers log meaningful TODO messages.
- [ ] Tests for manifest loading + row generation.
- [ ] Instructions for running (`uv run volo-simpleui DS1120-PD_app.yaml`).
