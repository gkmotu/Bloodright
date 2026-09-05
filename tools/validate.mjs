import { readSource, validateContent } from './content-lib.mjs';
const errors = validateContent(readSource());
if (errors.length) { console.error(errors.join('\n')); process.exit(1); }
console.log('Varenza source content is valid.');

