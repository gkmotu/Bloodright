# Architecture

Bloodright separates engine code from Varenza content.

- `src/engine`: turn rules, movement, collision, inventory, and content loading
- `src/game`: browser game presentation and input
- `src/editors`: terrain, item, and map authoring UI
- `content/source`: human-editable canonical content
- `content/published`: validated game-ready bundles
- `tools`: validation, publishing, and local serving
- `tests`: deterministic rules and content checks

Every content record has a stable namespaced ID. Maps reference terrain and
items only by ID. Publishing rejects broken references before creating a new
bundle. Editor browser drafts are deliberately separate from disk source data;
they can be exported as JSON for review and commit.

