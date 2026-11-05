import {readFile,writeFile} from 'node:fs/promises';
const source=JSON.parse(await readFile(new URL('../PoP_2_Demo_Coding_Pack/assets/design_tokens.json',import.meta.url),'utf8'));
const names={primary:'teal',text:'ink',canvas:'canvas',muted:'muted'};
let dart="// Generated from the canonical design_tokens.json. Run node scripts/generate-tokens.mjs.\nimport 'package:flutter/material.dart';\n";
for(const [key,name]of Object.entries(names))dart+=`const ${name}=Color(0xff${source.colors[key].slice(1)});\n`;
dart+='class PopSpacing {\n';for(const[key,value]of Object.entries(source.spacing))dart+=`static const double ${key}=${value};\n`;dart+='}\n';
await writeFile(new URL('../packages/ui/lib/src/tokens.dart',import.meta.url),dart);
