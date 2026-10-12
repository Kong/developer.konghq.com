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

// The Kong mark from the site header (viewBox units), pixelated at runtime.
const LOGO_PATHS = [
  "M11.6089 27.3795L12.4877 26.2563H18.9908L22.3805 30.5448L21.7779 31.9998H13.3916L13.5925 30.5448L11.6089 27.3795Z",
  "M13.5923 12.7572L16.7324 7.38525H20.3915L36.7927 26.25L35.5211 32.0002H28.4883L28.9295 30.3861L13.5923 12.7572Z",
  "M17.397 6.36383L18.9005 3.6105L23.4112 0L31.14 6.00018L30.1377 7.0132L31.483 8.85741V10.8315L27.6317 13.9485L21.1691 6.36383H17.397Z",
  "M5.45639 18.3602H7.49931L12.8264 13.9478L19.8861 22.0707L17.8949 25.029H11.3783L6.87867 30.695L5.84429 31.9987H0V25.0541L5.45639 18.3602Z",
];
const LOGO_WIDTH = 37;
const LOGO_HEIGHT = 32;
const LOGO_EYE = { x: 25, y: 5.5 };

const ORB = ["..RRR..", ".RRRRR.", "RRWRRRR", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..RRR.."];

// An open doorway with a down arrow (W) on a dark interior (K).
const DOOR = [
  "..GGGGGGGGGG..",
  ".GGKKKKKKKKGG.",
  "GGKKKKKKKKKKGG",
  "GKKKKKWWKKKKKG",
  "GKKKKKWWKKKKKG",
  "GKKKKKWWKKKKKG",
  "GKKKKKWWKKKKKG",
  "GKKKWWWWWWKKKG",
  "GKKKKWWWWKKKKG",
  "GKKKKKWWKKKKKG",
  "GKKKKKKKKKKKKG",
  "GKKKKKKKKKKKKG",
  "GKKKKKKKKKKKKG",
  "GKKKKKKKKKKKKG",
  "GKKKKKKKKKKKKG",
  "GKKKKKKKKKKKKG",
  "GGGGGGGGGGGGGG",
];

const HEART = [".RR.RR.", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."];

const EYE = [
  "..RRRRR..",
  ".R.....R.",
  "R..RRR..R",
  "R.RRWRR.R",
  "R..RRR..R",
  ".R.....R.",
  "..RRRRR..",
];

// The mark is four shapes: foot, torso, head and arm. Walk frames nudge each
// shape (in viewBox units) so the arm and foot swing while the body bobs.
const FOOT = 0;
const TORSO = 1;
const HEAD = 2;
const ARM = 3;
const WALK_CYCLE = [
  { [FOOT]: [4, -2], [ARM]: [-4, 0], [TORSO]: [0, -1.5], [HEAD]: [0, -1.5] },
  { [ARM]: [0, -1] },
  { [FOOT]: [-4, 0], [ARM]: [3, -3], [TORSO]: [0, -1.5], [HEAD]: [0, -1.5] },
  { [FOOT]: [0, -1] },
];

function logoRows(height, { eye = false, offsets = {}, pad = 0 } = {}) {
  const inner = Math.round((height * LOGO_WIDTH) / LOGO_HEIGHT);
  const width = inner + pad * 2;
  const unit = height / LOGO_HEIGHT;
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  LOGO_PATHS.forEach((d, i) => {
    const [dx, dy] = offsets[i] || [0, 0];
    ctx.setTransform(unit, 0, 0, unit, pad + dx * unit, dy * unit);
    ctx.fill(new Path2D(d));
  });
  const alpha = ctx.getImageData(0, 0, width, height).data;

  const rows = [];
  for (let y = 0; y < height; y++) {
    let row = "";
    for (let x = 0; x < width; x++) row += alpha[(y * width + x) * 4 + 3] > 100 ? "G" : ".";
    rows.push(row);
  }

  if (eye) {
    const [hx, hy] = offsets[HEAD] || [0, 0];
    const ex = pad + Math.round((LOGO_EYE.x + hx) * unit);
    const ey = Math.round((LOGO_EYE.y + hy) * unit);
    rows[ey] = rows[ey].slice(0, ex) + "K" + rows[ey].slice(ex + 1);
  }
  return rows;
}

// A monitor on a stand with the Kong mark stamped on the screen (X pixels).
function terminalRows(logo) {
  const width = 20;
  const screenHeight = 11;
  const screenWidth = width - 4;
  const rows = ["K".repeat(width), `K${"M".repeat(width - 2)}K`];
  for (let i = 0; i < screenHeight; i++) rows.push(`KM${"S".repeat(screenWidth)}MK`);
  rows.push(`K${"M".repeat(width - 2)}K`, "K".repeat(width));
  rows.push("........KMMK........", ".......KMMMMK.......");
  rows.push("K".repeat(width), "KMLMLMLMLMLMLMLMLMMK", "K".repeat(width));

  const top = 2 + Math.floor((screenHeight - logo.length) / 2);
  const left = 2 + Math.floor((screenWidth - logo[0].length) / 2);
  logo.forEach((logoRow, y) => {
    const chars = [...rows[top + y]];
    [...logoRow].forEach((char, x) => {
      if (char !== ".") chars[left + x] = "X";
    });
    rows[top + y] = chars.join("");
  });
  return rows;
}

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
  const terminal = terminalRows(logoRows(9));
  return {
    player: {
      idle: rasterise(logoRows(14, { eye: true, pad: 2 }), scale),
      walk: WALK_CYCLE.map((offsets) => rasterise(logoRows(14, { eye: true, pad: 2, offsets }), scale)),
    },
    terminal: {
      broken: [
        rasterise(terminal, scale, { S: "#2a000c", X: "#ff2b4f" }),
        rasterise(terminal, scale, { S: "#1a0008", X: "#7a1022" }),
      ],
      ok: rasterise(terminal, scale, { S: "#0f2a00", X: "#ccff00" }),
    },
    eye: rasterise(EYE, scale),
    door: [rasterise(DOOR, scale), rasterise(DOOR, scale, { G: "#ffffff", K: "#2f4a00", W: "#ccff00" })],
    orb: rasterise(ORB, 2),
    heart: rasterise(HEART, 2),
    heartEmpty: rasterise(HEART, 2, { R: "#3a3f47" }),
  };
}
