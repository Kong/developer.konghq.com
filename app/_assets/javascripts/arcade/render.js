// Drawing helpers. The canvas is a fixed overlay the size of the viewport, so
// world positions are drawn at (x - scrollX, y - scrollY).

import { LEDGE_HEIGHT } from "./world";

const GLYPHS =
  "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン01{}<>/=";
const FONT = 'ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace';
const LIME = "#ccff00";
const PALE = "#eaffb0";
const RED = "#ff2b4f";
const INK = "#0b0f0a";
const HEADER_OFFSET = 64;
const BRICK = 28;
const MINIMAP_WIDTH = 14;

// Stable pseudo-random value so glitch glyphs change a few times a second
// instead of every frame.
function hash(a, b) {
  const n = Math.sin(a * 127.1 + b * 311.7) * 43758.5453;
  return n - Math.floor(n);
}

function glyph(a, b) {
  return GLYPHS[Math.floor(hash(a, b) * GLYPHS.length)];
}

export class Rain {
  constructor(width, height) {
    this.size = 16;
    this.columns = Array.from({ length: Math.ceil(width / this.size) }, () => ({
      y: -Math.random() * height,
      speed: 300 + Math.random() * 500,
    }));
  }

  draw(ctx, width, height, dt, time) {
    ctx.fillStyle = "rgba(0, 0, 0, 0.12)";
    ctx.fillRect(0, 0, width, height);
    ctx.font = `${this.size}px ${FONT}`;
    this.columns.forEach((column, i) => {
      column.y += column.speed * dt;
      if (column.y > height + 200) column.y = -Math.random() * 300;
      const row = Math.floor(column.y / this.size);
      ctx.fillStyle = PALE;
      ctx.fillText(glyph(i, row + Math.floor(time * 10)), i * this.size, row * this.size);
      ctx.fillStyle = LIME;
      ctx.fillText(glyph(row, i), i * this.size, (row - 1) * this.size);
    });
  }
}

export function drawPrompt(ctx, width, height, lines, chars, time) {
  ctx.fillStyle = "#000";
  ctx.fillRect(0, 0, width, height);
  ctx.font = `20px ${FONT}`;
  ctx.fillStyle = LIME;
  ctx.shadowColor = LIME;
  ctx.shadowBlur = 8;

  const left = Math.max(32, width / 2 - 380);
  let top = height / 2 - lines.length * 16;
  let remaining = chars;
  lines.forEach((line) => {
    const shown = line.slice(0, Math.max(0, remaining));
    remaining -= line.length;
    ctx.fillText(shown, left, top);
    if (remaining <= 0 && remaining > -line.length - 1 && Math.floor(time * 2) % 2 === 0) {
      ctx.fillRect(left + ctx.measureText(shown).width + 4, top - 16, 10, 20);
    }
    top += 32;
  });
  ctx.shadowBlur = 0;
}

function drawLedge(ctx, segment, x, y, tick) {
  const { w } = segment;
  if (segment.corrupted && !segment.terminal) {
    // Corrupted ledges flicker and are no longer solid.
    ctx.globalAlpha = 0.3 + 0.3 * hash(segment.index, tick);
    ctx.fillStyle = "#3a0010";
    ctx.fillRect(x, y, w, LEDGE_HEIGHT);
    ctx.fillStyle = RED;
    for (let dx = 0; dx < w; dx += 12) {
      if (hash(segment.index + dx, tick) > 0.4) ctx.fillRect(x + dx, y, 6, 3);
    }
    ctx.globalAlpha = 1;
    ctx.font = `14px ${FONT}`;
    for (let i = 0; i < 2; i++) {
      ctx.fillText(glyph(segment.index + i, tick), x + hash(segment.index * 3 + i, tick) * (w - 14), y - 4);
    }
    return;
  }

  const body = segment.terminal ? "#3b4350" : "#2f4a00";
  const shade = segment.terminal ? "#262c35" : "#1a2a00";
  const half = LEDGE_HEIGHT / 2;
  ctx.fillStyle = INK;
  ctx.fillRect(x - 2, y - 2, w + 4, LEDGE_HEIGHT + 4);
  ctx.fillStyle = body;
  ctx.fillRect(x, y, w, LEDGE_HEIGHT);
  ctx.fillStyle = LIME;
  ctx.fillRect(x, y, w, 4);
  ctx.fillStyle = shade;
  ctx.fillRect(x, y + LEDGE_HEIGHT - 4, w, 4);
  // Two rows of staggered bricks.
  ctx.fillStyle = INK;
  ctx.fillRect(x, y + half, w, 2);
  for (let dx = BRICK; dx < w - 4; dx += BRICK) ctx.fillRect(x + dx, y + 4, 2, half - 4);
  for (let dx = BRICK / 2; dx < w - 4; dx += BRICK) ctx.fillRect(x + dx, y + half + 2, 2, half - 6);
}

// A shielded ledge carries a pulsing force field that flickers out in its
// last few seconds.
function drawShield(ctx, segment, x, y, time) {
  if (segment.shield <= 0 || segment.corrupted) return;
  if (segment.shield < 3 && Math.floor(time * 8) % 2) return;
  ctx.globalAlpha = 0.35 + 0.2 * Math.sin(time * 6);
  ctx.strokeStyle = "#7ff9ff";
  ctx.lineWidth = 2;
  ctx.strokeRect(x - 5, y - 6, segment.w + 10, LEDGE_HEIGHT + 11);
  ctx.globalAlpha = 1;
}

function drawLabel(ctx, text, centreX, y, color) {
  ctx.font = `bold 11px ${FONT}`;
  const width = ctx.measureText(text).width + 12;
  ctx.fillStyle = "rgba(0, 0, 0, 0.85)";
  ctx.fillRect(centreX - width / 2, y - 14, width, 18);
  ctx.fillStyle = color;
  ctx.textAlign = "center";
  ctx.fillText(text, centreX, y);
  ctx.textAlign = "left";
}

export function drawWorld(ctx, game, time) {
  const { world, sprites, player } = game;
  const sx = window.scrollX;
  const sy = window.scrollY;
  const height = window.innerHeight;
  const tick = Math.floor(time * 8);
  const visible = (y, margin = 80) => y > sy - margin && y < sy + height + margin;

  // Keep the level out from under the sticky site header.
  ctx.save();
  ctx.beginPath();
  ctx.rect(0, HEADER_OFFSET, window.innerWidth, height - HEADER_OFFSET);
  ctx.clip();

  // Corrupted docs: a red wash and drifting glyphs over each block.
  ctx.font = `14px ${FONT}`;
  world.blocks.forEach((block) => {
    if (!block.corrupted || !visible(block.y, block.h + 40)) return;
    const x = block.x - sx;
    const y = block.y - sy;
    ctx.fillStyle = "rgba(255, 43, 79, 0.07)";
    ctx.fillRect(x, y, block.w, block.h);
    ctx.fillStyle = RED;
    for (let i = 0; i < 2; i++) {
      ctx.fillText(
        glyph(block.index + i, tick),
        x + hash(block.index * 3 + i, tick) * (block.w - 14),
        y + 14 + hash(i, block.index) * Math.max(0, block.h - 14)
      );
    }
  });

  world.segments.forEach((segment) => {
    if (!visible(segment.y)) return;
    drawLedge(ctx, segment, segment.x - sx, segment.y - sy, tick);
    drawShield(ctx, segment, segment.x - sx, segment.y - sy, time);
  });

  if (game.exitDoor && visible(game.exitDoor.y, 120)) {
    const door = game.exitDoor;
    const sprite = sprites.door[Math.floor(time * 4) % 2];
    ctx.drawImage(sprite, door.x - sx, door.y - sy);
    drawLabel(ctx, "EXIT", door.x - sx + sprite.width / 2, door.y - sy - 10, LIME);
  }

  world.terminals.forEach((terminal) => {
    const pos = game.terminalPosition(terminal);
    if (!visible(pos.y, 120)) return;
    const sprite = terminal.patched ? sprites.terminal.ok : sprites.terminal.broken[tick % 2];
    const x = pos.x - sx;
    const y = pos.y - sy;
    ctx.drawImage(sprite, x, y);

    const label = terminal.patched ? `✓ ${terminal.plugin.name}` : terminal.plugin.name;
    drawLabel(ctx, label.toUpperCase(), x + sprite.width / 2, y - 10, terminal.patched ? LIME : RED);

    if (!terminal.patched && terminal.progress > 0) {
      ctx.fillStyle = "#000";
      ctx.fillRect(x - 4, y - 36, sprite.width + 8, 8);
      ctx.fillStyle = LIME;
      ctx.fillRect(x - 2, y - 34, (sprite.width + 4) * terminal.progress, 4);
    } else if (!terminal.patched && game.nearbyTerminal() === terminal) {
      drawLabel(ctx, "HOLD E", x + sprite.width / 2, y - 34, PALE);
    }
  });

  // The AI eye drifts towards whatever it corrupted last.
  if (game.eye) {
    ctx.drawImage(sprites.eye, game.eye.x - sx, game.eye.y - sy + Math.sin(time * 3) * 4);
  }

  game.orbs.forEach((orb) => {
    ctx.globalAlpha = Math.min(1, orb.life / 1.5);
    const pulse = 10 + Math.sin(time * 8 + orb.seed) * 3;
    ctx.fillStyle = "rgba(255, 43, 79, 0.25)";
    ctx.beginPath();
    ctx.arc(orb.x - sx, orb.y - sy, pulse, 0, Math.PI * 2);
    ctx.fill();
    ctx.drawImage(sprites.orb, orb.x - sx - sprites.orb.width / 2, orb.y - sy - sprites.orb.height / 2);
  });
  ctx.globalAlpha = 1;

  game.particles.forEach((p) => {
    ctx.globalAlpha = Math.max(0, p.life / p.maxLife);
    ctx.fillStyle = p.color;
    ctx.fillRect(p.x - sx, p.y - sy, 3, 3);
  });
  ctx.globalAlpha = 1;

  // Blink while invulnerable after a hit.
  if (player.invulnerable > 0 && Math.floor(time * 12) % 2) {
    ctx.restore();
    return;
  }

  // Walk cycle on the ground, squash and stretch around the feet, and a
  // little waddle while running.
  const walking = player.ground && Math.abs(player.vx) > 20;
  const frames = sprites.player.walk;
  const frame = walking ? frames[Math.floor(player.walkPhase) % frames.length] : sprites.player.idle;
  const footX = player.x + player.w / 2 - sx;
  const footY = player.y + player.h - sy;
  const lean = player.ground ? (player.vx / 280) * 0.12 : 0;
  const waddle = walking ? Math.sin(player.walkPhase * (Math.PI / 2)) * 0.06 : 0;
  ctx.save();
  ctx.translate(footX, footY);
  ctx.rotate(waddle);
  ctx.transform(1, 0, -lean * player.facing, 1, 0, 0);
  ctx.scale(player.facing * (2 - player.squash), player.squash);
  ctx.drawImage(frame, -frame.width / 2, -frame.height + game.scale);
  ctx.restore();
  ctx.restore();
}

function panel(ctx, x, y, w, h, border = LIME) {
  ctx.fillStyle = "rgba(0, 0, 0, 0.85)";
  ctx.fillRect(x, y, w, h);
  ctx.strokeStyle = border;
  ctx.lineWidth = 2;
  ctx.strokeRect(x + 1, y + 1, w - 2, h - 2);
}

export function drawHud(ctx, game, loseRatio) {
  const { world, sprites } = game;
  const ratio = world.corruptionRatio();
  const width = 320;
  const x = window.innerWidth - width - 16;
  const y = HEADER_OFFSET + 12;
  const height = 104 + world.terminals.length * 18;
  panel(ctx, x, y, width, height);

  ctx.font = `bold 12px ${FONT}`;
  ctx.fillStyle = PALE;
  ctx.fillText("MISSION: ENABLE EVERY KONG PLUGIN", x + 14, y + 22);
  ctx.fillText("TO GOVERN THE ROGUE AI", x + 14, y + 38);

  for (let i = 0; i < game.maxLives; i++) {
    ctx.drawImage(i < game.lives ? sprites.heart : sprites.heartEmpty, x + 14 + i * 22, y + 48);
  }
  if (game.sfx?.muted) {
    ctx.fillStyle = "#8a9099";
    ctx.fillText("MUTED", x + width - 60, y + 60);
  }

  ctx.drawImage(sprites.eye, x + 12, y + 70, sprites.eye.width * 0.6, sprites.eye.height * 0.6);
  ctx.font = `bold 14px ${FONT}`;
  ctx.fillStyle = RED;
  ctx.fillText(`${Math.round(ratio * 100)}%`, x + 44, y + 86);
  const barX = x + 96;
  const barWidth = width - 112;
  ctx.fillStyle = "#330a12";
  ctx.fillRect(barX, y + 74, barWidth, 14);
  ctx.fillStyle = RED;
  ctx.fillRect(barX, y + 74, Math.min(1, ratio / loseRatio) * barWidth, 14);
  ctx.fillStyle = "#fff";
  ctx.fillRect(barX + barWidth - 1, y + 72, 2, 18);

  ctx.font = `12px ${FONT}`;
  world.terminals.forEach((terminal, i) => {
    ctx.fillStyle = terminal.patched ? LIME : "#8a9099";
    ctx.fillText(`${terminal.patched ? "[✓]" : "[ ]"} ${terminal.plugin.name.toUpperCase()}`, x + 14, y + 116 + i * 18);
  });
  return y + height;
}

// A strip down the right edge showing the whole page: corruption in red,
// terminals, the current view and the player.
export function drawMinimap(ctx, game, top) {
  const { world, player } = game;
  const pageHeight = document.documentElement.scrollHeight;
  const x = window.innerWidth - MINIMAP_WIDTH - 16;
  const bottom = window.innerHeight - 60;
  const height = bottom - top;
  if (height < 80) return;
  const toY = (y) => top + (y / pageHeight) * height;

  panel(ctx, x - 3, top - 3, MINIMAP_WIDTH + 6, height + 6);
  ctx.fillStyle = RED;
  world.blocks.forEach((block) => {
    if (block.corrupted) ctx.fillRect(x, toY(block.y), MINIMAP_WIDTH, Math.max(2, (block.h / pageHeight) * height));
  });

  const view = window.scrollY;
  ctx.strokeStyle = PALE;
  ctx.lineWidth = 1;
  ctx.strokeRect(x - 1.5, toY(view), MINIMAP_WIDTH + 3, (window.innerHeight / pageHeight) * height);

  world.terminals.forEach((terminal) => {
    ctx.fillStyle = INK;
    ctx.fillRect(x - 2, toY(terminal.segment.y) - 4, MINIMAP_WIDTH + 4, 8);
    ctx.fillStyle = terminal.patched ? LIME : "#ff8a9c";
    ctx.fillRect(x, toY(terminal.segment.y) - 2, MINIMAP_WIDTH, 4);
  });

  if (game.exitDoor && Math.floor(performance.now() / 250) % 2) {
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(x - 3, toY(game.exitDoor.y) - 5, MINIMAP_WIDTH + 6, 10);
  }

  const py = toY(player.y + player.h / 2);
  ctx.fillStyle = LIME;
  ctx.beginPath();
  ctx.moveTo(x - 4, py);
  ctx.lineTo(x - 12, py - 6);
  ctx.lineTo(x - 12, py + 6);
  ctx.fill();
}

export function drawKeybar(ctx, width, height, exitArmed, time) {
  const text = exitArmed
    ? "PRESS ESC AGAIN TO RETURN TO THE DOCS"
    : "←→ MOVE   SPACE JUMP (×2)   ↓ DROP · HOLD TO FALL   HOLD E ENABLE PLUGIN   WHEEL LOOK   M MUTE   ESC ×2 EXIT";
  ctx.font = `bold 12px ${FONT}`;
  const barWidth = Math.min(width - 32, ctx.measureText(text).width + 40);
  const x = (width - barWidth) / 2;
  const y = height - 44;
  panel(ctx, x, y, barWidth, 32, exitArmed ? RED : LIME);
  ctx.fillStyle = exitArmed && Math.floor(time * 4) % 2 ? RED : PALE;
  ctx.textAlign = "center";
  ctx.fillText(text, width / 2, y + 20);
  ctx.textAlign = "left";
}

export function drawToast(ctx, width, toast) {
  const alpha = Math.min(1, toast.time * 2);
  ctx.globalAlpha = alpha;
  ctx.font = `bold 18px ${FONT}`;
  const titleWidth = ctx.measureText(toast.title).width;
  ctx.font = `14px ${FONT}`;
  const textWidth = ctx.measureText(toast.text).width;
  const w = Math.max(titleWidth, textWidth) + 48;
  const x = (width - w) / 2;
  const y = HEADER_OFFSET + 24;
  panel(ctx, x, y, w, 64, toast.color === "red" ? RED : LIME);
  ctx.textAlign = "center";
  ctx.font = `bold 18px ${FONT}`;
  ctx.fillStyle = toast.color === "red" ? RED : LIME;
  ctx.fillText(toast.title, width / 2, y + 26);
  ctx.font = `14px ${FONT}`;
  ctx.fillStyle = PALE;
  ctx.fillText(toast.text, width / 2, y + 48);
  ctx.textAlign = "left";
  ctx.globalAlpha = 1;
}

export function drawBanner(ctx, width, height, title, lines, color) {
  ctx.font = `15px ${FONT}`;
  const longest = Math.max(...lines.map((line) => ctx.measureText(line).width));
  const w = Math.min(Math.max(560, longest + 64), width - 32);
  const h = 72 + lines.length * 28;
  const x = (width - w) / 2;
  const y = (height - h) / 2;
  panel(ctx, x, y, w, h, color === "red" ? RED : LIME);
  ctx.textAlign = "center";
  ctx.font = `bold 28px ${FONT}`;
  ctx.fillStyle = color === "red" ? RED : LIME;
  ctx.fillText(title, width / 2, y + 44);
  ctx.font = `15px ${FONT}`;
  ctx.fillStyle = PALE;
  lines.forEach((line, i) => ctx.fillText(line, width / 2, y + 80 + i * 28));
  ctx.textAlign = "left";
}
