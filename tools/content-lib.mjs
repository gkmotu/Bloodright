import fs from 'node:fs';
import path from 'node:path';

export function readSource(root = process.cwd()) {
  const read = p => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8'));
  const mapDir = path.join(root, 'content/source/maps');
  return {
    terrain: read('content/source/terrain.json'),
    items: read('content/source/items.json'),
    descriptions: read('content/source/descriptions.json'),
    settings: read('content/source/app-settings.json'),
    maps: fs.readdirSync(mapDir).filter(f => f.endsWith('.json')).map(f => read(`content/source/maps/${f}`))
  };
}

export function validateContent(content) {
  const errors = [];
  const all = [...content.terrain, ...content.items, ...content.descriptions, ...content.maps];
  const ids = new Set();
  for (const entry of all) {
    if (!entry.id || !/^[a-z0-9._-]+$/.test(entry.id)) errors.push(`Invalid or missing id: ${entry.id ?? '(missing)'}`);
    if (ids.has(entry.id)) errors.push(`Duplicate id: ${entry.id}`);
    ids.add(entry.id);
  }
  const terrainIds = new Set(content.terrain.map(t => t.id));
  const itemIds = new Set(content.items.map(i => i.id));
  if (!content.settings?.id) errors.push('Application settings need a stable ID.');
  for (const entry of content.descriptions) {
    if (!entry.name) errors.push(`${entry.id}: missing name`);
    if (!entry.tagId) errors.push(`${entry.id}: missing tag ID`);
    if (!['prop', 'item', 'terrain', 'character', 'ui'].includes(entry.type)) errors.push(`${entry.id}: invalid type ${entry.type}`);
    if (!entry.symbol || [...entry.symbol].length !== 1) errors.push(`${entry.id}: symbol must be one character`);
    if (!['small', 'large'].includes(entry.glyphSize)) errors.push(`${entry.id}: glyphSize must be small or large`);
  }
  for (const map of content.maps) {
    if (map.tiles.length !== map.height) errors.push(`${map.id}: expected ${map.height} rows`);
    map.tiles.forEach((row, y) => {
      if (row.length !== map.width) errors.push(`${map.id}: row ${y} width is ${row.length}, expected ${map.width}`);
      [...row].forEach(ch => {
        if (!map.legend[ch]) errors.push(`${map.id}: missing legend entry for '${ch}'`);
        else if (!terrainIds.has(map.legend[ch])) errors.push(`${map.id}: unknown terrain ${map.legend[ch]}`);
      });
    });
    for (const placed of map.items ?? []) if (!itemIds.has(placed.itemId)) errors.push(`${map.id}: unknown item ${placed.itemId}`);
    const s = map.playerStart;
    if (!s || s.x < 0 || s.y < 0 || s.x >= map.width || s.y >= map.height) errors.push(`${map.id}: invalid player start`);
  }
  return errors;
}
