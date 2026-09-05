import fs from 'node:fs';
import path from 'node:path';
import { readSource, validateContent } from './content-lib.mjs';

const content = readSource();
const errors = validateContent(content);
if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}
const output = {schemaVersion:1, publishedAt:new Date().toISOString(), ...content};
const dir = path.resolve('content/published');
fs.mkdirSync(dir, {recursive:true});
fs.writeFileSync(path.join(dir, 'content.json'), JSON.stringify(output, null, 2) + '\n');
console.log(`Published ${content.terrain.length} terrain, ${content.items.length} items, ${content.descriptions.length} descriptions, ${content.maps.length} maps.`);
