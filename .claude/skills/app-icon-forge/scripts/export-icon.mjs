#!/usr/bin/env node
// Export an SVG app icon to the Shopify App Store PNG set.
// Usage: node export-icon.mjs <icon.svg> [--brand-color #RRGGBB] [--out dir]

import { existsSync, mkdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import sharp from 'sharp';

function parseArgs(argv) {
  const out = { out: './icon-exports', brand: '#FFFFFF', svg: null };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--out') out.out = argv[++i];
    else if (arg === '--brand-color') out.brand = argv[++i];
    else if (!arg.startsWith('-') && out.svg === null) out.svg = arg;
  }
  return out;
}

function hexToRgb(hex) {
  const match = /^#?([0-9a-f]{6})$/i.exec(String(hex).trim());
  if (!match) return { r: 255, g: 255, b: 255, alpha: 1 };
  const n = parseInt(match[1], 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, alpha: 1 };
}

const { svg, out, brand } = parseArgs(process.argv.slice(2));
if (!svg || !existsSync(svg)) {
  console.error('usage: node export-icon.mjs <icon.svg> [--brand-color #RRGGBB] [--out dir]');
  process.exit(1);
}

const svgBuffer = readFileSync(resolve(svg));
const outDir = resolve(out);
mkdirSync(outDir, { recursive: true });

const sizes = [
  ['shopify-listing-1200.png', 1200],
  ['app-store-1024.png', 1024],
  ['app-store-512.png', 512],
  ['favicon-64.png', 64],
  ['favicon-32.png', 32],
];

for (const [name, size] of sizes) {
  await sharp(svgBuffer, { density: 384 })
    .resize(size, size, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toFile(join(outDir, name));
}

const socialWidth = 1200;
const socialHeight = 630;
const iconSize = 420;
const iconBuffer = await sharp(svgBuffer, { density: 384 })
  .resize(iconSize, iconSize, {
    fit: 'contain',
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  })
  .png()
  .toBuffer();

await sharp({
  create: {
    width: socialWidth,
    height: socialHeight,
    channels: 4,
    background: hexToRgb(brand),
  },
})
  .composite([
    {
      input: iconBuffer,
      left: Math.round((socialWidth - iconSize) / 2),
      top: Math.round((socialHeight - iconSize) / 2),
    },
  ])
  .png()
  .toFile(join(outDir, 'social-1200x630.png'));

console.log(`Wrote ${sizes.length + 1} files to ${outDir}`);
