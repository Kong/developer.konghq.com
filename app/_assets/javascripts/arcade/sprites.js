// Pixel art lives here as strings: one character per pixel, "." is transparent.
// Sprites are rasterised once into offscreen canvases with a 1px dark outline
// so they read on both the light and dark themes.

const PALETTE = {
  G: "#ccff00", // Kong lime
  D: "#5c8a00",
  K: "#0b0f0a",
  W: "#ffffff",
  M: "#5b6470",
  L: "#c9d1d9",
  R: "#ff2b4f",
};

const OUTLINE = "#0b0f0a";

const PLAYER_HEAD = [
  "...GGGG...",
  "..GGGGGG..",
  "..GGKWKW..",
  "..GGGGGG..",
];

const PLAYER = {
  idle: [
    ...PLAYER_HEAD,
    "...GGGG...",
    "..DDDDDD..",
    ".DDDDDDDD.",
    ".G.DDDD.G.",
    "...DDDD...",
    "...D..D...",
    "...D..D...",
    "..GG..GG..",
  ],
  run1: [
    ...PLAYER_HEAD,
    "...GGGG...",
    "..DDDDDD..",
    ".DDDDDDDG.",
    "G..DDDD...",
    "...DDDD...",
    "..D....D..",
    ".D......D.",
    "GG.....GG.",
  ],
  run2: [
    ...PLAYER_HEAD,
    "...GGGG...",
    "..DDDDDD..",
    ".GDDDDDDD.",
    "...DDDD..G",
    "...DDDD...",
    "....DD....",
    "....D.D...",
    "...GG.GG..",
  ],
  jump: [
    ...PLAYER_HEAD,
    "G..GGGG..G",
    "GDDDDDDDDG",
    "..DDDDDD..",
    "...DDDD...",
    "...DDDD...",
    "..D....D..",
    ".GG....GG.",
    "..........",
  ],
};

// S = screen, X = screen glyph. Colours are swapped per terminal state.
const TERMINAL_BROKEN = [
  "KKKKKKKKKKKK",
  "KMMMMMMMMMMK",
  "KMSSSSXSSSMK",
  "KMSSSSXSSSMK",
  "KMSSSSXSSSMK",
  "KMSSSSSSSSMK",
  "KMSSSSXSSSMK",
  "KMMMMMMMMMMK",
  "KKKKKKKKKKKK",
  "....KMMK....",
  "...KMMMMK...",
  "KKKKKKKKKKKK",
  "KMLMLMLMLMMK",
  "KKKKKKKKKKKK",
];

const TERMINAL_OK = [
  "KKKKKKKKKKKK",
  "KMMMMMMMMMMK",
  "KMSSSSSSSSMK",
  "KMSSSSSSXSMK",
  "KMSXSSSXSSMK",
  "KMSSXSXSSSMK",
  "KMSSSXSSSSMK",
  "KMMMMMMMMMMK",
  "KKKKKKKKKKKK",
  "....KMMK....",
  "...KMMMMK...",
  "KKKKKKKKKKKK",
  "KMLMLMLMLMMK",
  "KKKKKKKKKKKK",
];

const EYE = [
  "..RRRRR..",
  ".R.....R.",
  "R..RRR..R",
  "R.RRWRR.R",
  "R..RRR..R",
  ".R.....R.",
  "..RRRRR..",
];

function rasterise(rows, scale, palette = {}) {
  const colors = { ...PALETTE, ...palette };
  const width = rows[0].length + 2;
  const height = rows.length + 2;
  const opaque = (x, y) => rows[y]?.[x] !== undefined && rows[y][x] !== ".";

  const canvas = document.createElement("canvas");
  canvas.width = width * scale;
  canvas.height = height * scale;
  const ctx = canvas.getContext("2d");

  // Outline pass: any transparent pixel touching an opaque one.
  ctx.fillStyle = OUTLINE;
  for (let y = -1; y <= rows.length; y++) {
    for (let x = -1; x <= rows[0].length; x++) {
      if (opaque(x, y)) continue;
      if (opaque(x - 1, y) || opaque(x + 1, y) || opaque(x, y - 1) || opaque(x, y + 1)) {
        ctx.fillRect((x + 1) * scale, (y + 1) * scale, scale, scale);
      }
    }
  }

  rows.forEach((row, y) => {
    [...row].forEach((char, x) => {
      if (char === ".") return;
      ctx.fillStyle = colors[char];
      ctx.fillRect((x + 1) * scale, (y + 1) * scale, scale, scale);
    });
  });

  return canvas;
}

export function makeSprites(scale) {
  return {
    player: {
      idle: rasterise(PLAYER.idle, scale),
      run: [rasterise(PLAYER.run1, scale), rasterise(PLAYER.run2, scale)],
      jump: rasterise(PLAYER.jump, scale),
    },
    terminal: {
      broken: [
        rasterise(TERMINAL_BROKEN, scale, { S: "#3a0010", X: "#ff2b4f" }),
        rasterise(TERMINAL_BROKEN, scale, { S: "#24000a", X: "#7a1022" }),
      ],
      ok: rasterise(TERMINAL_OK, scale, { S: "#ccff00", X: "#0b0f0a" }),
    },
    eye: rasterise(EYE, scale),
  };
}
