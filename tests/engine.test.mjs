import test from 'node:test';
import assert from 'node:assert/strict';
import { readSource, validateContent } from '../tools/content-lib.mjs';
import { createGame, move, pickup } from '../src/engine/core.js';

const content = readSource();
test('source content validates', () => assert.deepEqual(validateContent(content), []));
test('walls stop the player and floor permits movement', () => {
  const game = createGame(content);
  game.player.x = 1; game.player.y = 1;
  assert.equal(move(game, -1, 0), false);
  assert.equal(move(game, 1, 0), true);
  assert.deepEqual({x:game.player.x,y:game.player.y},{x:2,y:1});
});
test('items can be collected', () => {
  const game = createGame(content);
  game.player.x = 5; game.player.y = 4;
  assert.equal(pickup(game), true);
  assert.equal(game.player.inventory[0], 'bloodright.weapon.rustblade');
});
