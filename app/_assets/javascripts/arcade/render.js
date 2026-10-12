// Drawing helpers. The canvas is a fixed overlay the size of the viewport, so
// world positions are drawn at (x - scrollX, y - scrollY).

const GLYPHS =
  "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン01{}<>/=";
const FONT = 'ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace';
const LIME = "#ccff00";
const RED = "#ff2b4f";
const HEADER_OFFSET = 64;

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
      ctx.fillStyle = "#eaffb0";
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

  const left = Math.max(32, width / 2 - 320);
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

function inView(rect, scrollY, height) {
  return rect.y + rect.h > scrollY && rect.y < scrollY + height;
}

export function drawWorld(ctx, game, time) {
  const { world, sprites, player, scale } = game;
  const sx = window.scrollX;
  const sy = window.scrollY;
  const height = window.innerHeight;
  const dark = document.documentElement.classList.contains("dark");
  const tick = Math.floor(time * 8);

  // Platform hints: a faint ledge on solids, red static on corrupted blocks.
  world.platforms.forEach((p) => {
    if (!inView(p, sy, height)) return;
    const x = p.x - sx;
    const y = p.y - sy;
    if (p.corrupted && !p.terminal) {
      ctx.fillStyle = "rgba(255, 43, 79, 0.08)";
      ctx.fillRect(x, y, p.w, p.h);
      ctx.fillStyle = RED;
      for (let dx = 0; dx < p.w; dx += 12) {
        if (hash(p.index + dx, tick) > 0.45) ctx.fillRect(x + dx, y, 6, 2);
      }
      ctx.font = `14px ${FONT}`;
      for (let i = 0; i < 3; i++) {
        const r = hash(p.index * 3 + i, tick);
        ctx.fillText(glyph(p.index + i, tick), x + r * (p.w - 14), y + 14 + hash(i, p.index) * Math.max(0, p.h - 14));
      }
    } else {
      ctx.fillStyle = p.protected
        ? "rgba(204, 255, 0, 0.55)"
        : dark
          ? "rgba(204, 255, 0, 0.22)"
          : "rgba(70, 110, 0, 0.35)";
      ctx.fillRect(x, y, p.w, 2);
    }
  });

  world.terminals.forEach((terminal) => {
    const pos = game.terminalPosition(terminal);
    if (pos.y + 60 < sy || pos.y > sy + height) return;
    const sprite = terminal.patched ? sprites.terminal.ok : sprites.terminal.broken[tick % 2];
    ctx.drawImage(sprite, pos.x - sx, pos.y - sy);

    if (!terminal.patched && terminal.progress > 0) {
      ctx.fillStyle = "#000";
      ctx.fillRect(pos.x - sx - 4, pos.y - sy - 14, sprite.width + 8, 8);
      ctx.fillStyle = LIME;
      ctx.fillRect(pos.x - sx - 2, pos.y - sy - 12, (sprite.width + 4) * terminal.progress, 4);
    }
  });

  // The AI eye drifts towards whatever it corrupted last.
  if (game.eye) {
    ctx.drawImage(sprites.eye, game.eye.x - sx, game.eye.y - sy + Math.sin(time * 3) * 4);
  }

  game.particles.forEach((p) => {
    ctx.globalAlpha = Math.max(0, p.life / p.maxLife);
    ctx.fillStyle = p.color;
    ctx.fillRect(p.x - sx, p.y - sy, scale, scale);
  });
  ctx.globalAlpha = 1;

  const frame = !player.ground
    ? sprites.player.jump
    : Math.abs(player.vx) > 20
      ? sprites.player.run[Math.floor(time * 10) % 2]
      : sprites.player.idle;
  const drawX = player.x + player.w / 2 - frame.width / 2 - sx;
  const drawY = player.y + player.h - frame.height + scale - sy;
  ctx.save();
  if (player.facing < 0) {
    ctx.translate(drawX + frame.width, drawY);
    ctx.scale(-1, 1);
    ctx.drawImage(frame, 0, 0);
  } else {
    ctx.drawImage(frame, drawX, drawY);
  }
  ctx.restore();
}

function panel(ctx, x, y, w, h) {
  ctx.fillStyle = "rgba(0, 0, 0, 0.82)";
  ctx.fillRect(x, y, w, h);
  ctx.strokeStyle = LIME;
  ctx.lineWidth = 2;
  ctx.strokeRect(x + 1, y + 1, w - 2, h - 2);
}

export function drawHud(ctx, game, time) {
  const { world, sprites } = game;
  const ratio = world.corruptionRatio();
  const patched = world.terminals.filter((t) => t.patched).length;
  // Top right sits over the sidebar, away from the content column.
  const x = window.innerWidth - 316;
  const y = HEADER_OFFSET + 12;

  panel(ctx, x, y, 300, game.hintTime > 0 ? 112 : 72);
  ctx.font = `bold 14px ${FONT}`;
  ctx.fillStyle = LIME;
  ctx.fillText(`TERMINALS ${patched}/${world.terminals.length}`, x + 14, y + 24);
  ctx.fillText(game.sfx?.muted ? "MUTED" : "", x + 230, y + 24);

  ctx.drawImage(sprites.eye, x + 12, y + 36, sprites.eye.width * 0.6, sprites.eye.height * 0.6);
  ctx.fillStyle = RED;
  ctx.fillText(`${Math.round(ratio * 100)}%`, x + 44, y + 54);
  const barX = x + 96;
  ctx.fillStyle = "#330a12";
  ctx.fillRect(barX, y + 42, 186, 14);
  ctx.fillStyle = RED;
  ctx.fillRect(barX, y + 42, Math.min(1, ratio / 0.6) * 186, 14);
  ctx.fillStyle = "#fff";
  ctx.fillRect(barX + 185, y + 40, 2, 18);

  if (game.hintTime > 0) {
    ctx.font = `12px ${FONT}`;
    ctx.fillStyle = Math.floor(time * 2) % 2 ? "#eaffb0" : LIME;
    ctx.fillText("←→ MOVE  SPACE JUMP  ↓ PATCH/DROP", x + 14, y + 80);
    ctx.fillText("M MUTE  ESC QUIT", x + 14, y + 98);
  }
}

export function drawBanner(ctx, width, height, title, lines, color) {
  const w = Math.min(560, width - 32);
  const h = 72 + lines.length * 28;
  const x = (width - w) / 2;
  const y = (height - h) / 2;
  panel(ctx, x, y, w, h);
  ctx.textAlign = "center";
  ctx.font = `bold 28px ${FONT}`;
  ctx.fillStyle = color === "red" ? RED : LIME;
  ctx.fillText(title, width / 2, y + 44);
  ctx.font = `15px ${FONT}`;
  ctx.fillStyle = "#eaffb0";
  lines.forEach((line, i) => ctx.fillText(line, width / 2, y + 80 + i * 28));
  ctx.textAlign = "left";
}
