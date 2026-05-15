// Bullet patterns. Each is (enemy, t, player) -> bullets[].
// t is the enemy's frame counter; enemy.seed makes per-enemy variation
// deterministic, which is how Touhou-style patterns stay solvable:
// shapes look random but the gaps are always the same width.

const TWO_PI = Math.PI * 2;

function aimAngle(enemy, player) {
  return Math.atan2(player.y - enemy.y, player.x - enemy.x);
}

function bullet(enemy, angle, speed, r = 5.5) {
  return {
    x: enemy.x,
    y: enemy.y + 10,
    vx: Math.cos(angle) * speed,
    vy: Math.sin(angle) * speed,
    r,
  };
}

function jitter(n, amount) {
  const v = Math.sin(n * 12.9898) * 43758.5453;
  return ((v - Math.floor(v)) - 0.5) * 2 * amount;
}

export const patterns = {
  aimed(enemy, t, player) {
    if (t % 90 !== 0) return [];
    const a = aimAngle(enemy, player) + jitter(t + enemy.seed, 0.05);
    return [bullet(enemy, a, 2.7)];
  },

  spread(enemy, t, player) {
    if (t % 110 !== 0) return [];
    const center = aimAngle(enemy, player);
    const arc = 0.9;
    const n = 5;
    const out = [];
    for (let i = 0; i < n; i++) {
      const a = center - arc / 2 + (arc / (n - 1)) * i + jitter(t + enemy.seed + i, 0.02);
      out.push(bullet(enemy, a, 2.3));
    }
    return out;
  },

  ring(enemy, t, player) {
    if (t % 130 !== 0) return [];
    const n = 10;
    const offset = jitter(enemy.seed + t, Math.PI / n);
    const out = [];
    for (let i = 0; i < n; i++) {
      const a = offset + (i / n) * TWO_PI;
      out.push(bullet(enemy, a, 2.0));
    }
    return out;
  },

  stream(enemy, t, player) {
    if (t % 9 !== 0) return [];
    const base = aimAngle(enemy, player);
    const sweep = Math.sin((t + enemy.seed) / 55) * 0.55;
    const a = base + sweep + jitter(t + enemy.seed, 0.02);
    return [bullet(enemy, a, 2.5, 5)];
  },
};

export const PATTERN_KEYS = Object.keys(patterns);
export const DEFAULT_PATTERN = PATTERN_KEYS[0];
const PATTERN_DURATION = 360;

export function pickPattern(seed) {
  return PATTERN_KEYS[Math.abs(seed) % PATTERN_KEYS.length];
}

// Each enemy rotates through patterns independently — the seed offsets its
// phase so the wave doesn't switch in unison.
export function activePattern(enemy) {
  const phase = Math.floor((enemy.t + enemy.seed * 17) / PATTERN_DURATION);
  return PATTERN_KEYS[Math.abs(phase) % PATTERN_KEYS.length];
}
