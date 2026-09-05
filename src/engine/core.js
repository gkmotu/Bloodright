export function indexContent(content) {
  return {
    ...content,
    terrainById: Object.fromEntries(content.terrain.map(x => [x.id, x])),
    itemById: Object.fromEntries(content.items.map(x => [x.id, x]))
  };
}

export function createGame(content, mapId) {
  const indexed = indexContent(content);
  const map = indexed.maps.find(m => m.id === mapId) ?? indexed.maps[0];
  return {
    content:indexed, map, turn:0,
    player:{...map.playerStart, hp:10, maxHp:10, inventory:[]},
    groundItems:(map.items ?? []).map((x, n) => ({...x, instanceId:`ground-${n}`})),
    messages:[`You enter ${map.name}.`, 'Find the Rustblade and Redleaf Tonic.']
  };
}

export function terrainAt(state, x, y) {
  if (x < 0 || y < 0 || x >= state.map.width || y >= state.map.height) return null;
  return state.content.terrainById[state.map.legend[state.map.tiles[y][x]]];
}

export function move(state, dx, dy) {
  const target = terrainAt(state, state.player.x + dx, state.player.y + dy);
  if (!target?.walkable) {
    state.messages.push(target ? `${target.name} blocks your path.` : 'The dark has no road for you.');
    return false;
  }
  state.player.x += dx; state.player.y += dy; state.turn++;
  const here = state.groundItems.find(i => i.x === state.player.x && i.y === state.player.y);
  if (here) state.messages.push(`You see ${state.content.itemById[here.itemId].name}. Press G to take it.`);
  return true;
}

export function pickup(state) {
  const n = state.groundItems.findIndex(i => i.x === state.player.x && i.y === state.player.y);
  if (n < 0) { state.messages.push('There is nothing here to take.'); return false; }
  const [placed] = state.groundItems.splice(n, 1);
  state.player.inventory.push(placed.itemId); state.turn++;
  state.messages.push(`You take ${state.content.itemById[placed.itemId].name}.`);
  return true;
}

export function useItem(state, inventoryIndex) {
  const id = state.player.inventory[inventoryIndex];
  const item = state.content.itemById[id];
  if (!item) return false;
  if (item.effect?.kind === 'heal') {
    const before = state.player.hp;
    state.player.hp = Math.min(state.player.maxHp, state.player.hp + item.effect.amount);
    state.player.inventory.splice(inventoryIndex, 1); state.turn++;
    state.messages.push(`You drink ${item.name} and recover ${state.player.hp - before} health.`);
  } else state.messages.push(`${item.name} is ready for battles yet to come.`);
  return true;
}

