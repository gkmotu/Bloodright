# Bloodright

See [PHONE_ALERTS.md](PHONE_ALERTS.md) to connect both Android phones to shared Bloodright build notifications.

The first native Godot prototype for Isabelle's Varenza roguelike. It includes
a turn-based playable vault, content-tool foundations, and a validated
source-to-published content pipeline.

## Run

1. Open `project.godot` in Godot 4.7 or newer.
2. Press **F6** or the Run Project button.
3. Choose **Enter Varenza**.

Use arrow keys or WASD to move, `G` to pick up an item, `I` for inventory,
and `R` to restart. You can also click the on-screen controls.

## Content workflow

- Editable content lives in `content/source`.
- Run `npm run validate` to check it.
- Run `npm run publish` to generate `content/published/content.json`.
- Terrain and item definitions can already be inspected inside the native
  toolkit screens. Visual editing and map painting are the next milestone.

## Commands

- `npm start` - optional browser prototype server
- `npm test` - engine and content tests
- `npm run validate` - validate source content
- `npm run publish` - rebuild published content
