import { patterns, DEFAULT_PATTERN, pickPattern, activePattern } from "./patterns";

const FIXED_DT = 1000 / 60;
const PLAYER_SPEED = 4.2;
const PLAYER_FOCUS_SPEED = 1.8;
const PLAYER_FIRE_INTERVAL = 6;
const PLAYER_BULLET_SPEED = 9;
const PLAYER_HITBOX = 3;
const BOSS_HP_BASE = 28;
const BOSS_HP_SCALING = 8;
const STAGE_HP_BONUS = 16;
const STAGES_TOTAL = 3;
const STAGE_BOSS_COUNTS = [0, 2, 2, 3];
const ENEMY_SIZE = 48;
const MINION_HP = 1;
const MINION_HITBOX = 11;
const MINION_SPEED = 1.5;
const FADE_IN_MS = 900;
const POWER_MAX = 4;
const BOMB_START = 3;
const BOMB_DURATION = 60;
const LASER_HALF_WIDTH = 18;
const POWERUP_PICKUP_RADIUS = 22;
const POWERUP_MAGNET_RADIUS = 110;

// Player shot configuration per power level.
const POWER_PATTERNS = {
  1: [
    { dx: -7, dy: -12, vx: 0 },
    { dx: 7, dy: -12, vx: 0 },
  ],
  2: [
    { dx: -10, dy: -12, vx: 0 },
    { dx: -4, dy: -14, vx: 0 },
    { dx: 4, dy: -14, vx: 0 },
    { dx: 10, dy: -12, vx: 0 },
  ],
  3: [
    { dx: -12, dy: -12, vx: 0 },
    { dx: -5, dy: -14, vx: 0 },
    { dx: 5, dy: -14, vx: 0 },
    { dx: 12, dy: -12, vx: 0 },
    { dx: -18, dy: -8, vx: -1.6 },
    { dx: 18, dy: -8, vx: 1.6 },
  ],
  4: [
    { dx: -14, dy: -12, vx: -0.3 },
    { dx: -7, dy: -14, vx: 0 },
    { dx: -2, dy: -16, vx: 0 },
    { dx: 2, dy: -16, vx: 0 },
    { dx: 7, dy: -14, vx: 0 },
    { dx: 14, dy: -12, vx: 0.3 },
    { dx: -22, dy: -8, vx: -2.0 },
    { dx: 22, dy: -8, vx: 2.0 },
  ],
};

// Boss roaming styles. Seed picks one so neighbours don't move in lockstep.
const MOVE_FNS = [
  (e) => {
    e.x = e.baseX + Math.sin(e.t / 60) * 110;
    e.y = e.baseY + Math.sin(e.t / 95) * 24;
  },
  (e) => {
    e.x = e.baseX + Math.sin(e.t / 45) * 100;
    e.y = e.baseY + Math.sin(e.t / 90) * 36;
  },
  (e) => {
    e.x = e.baseX + Math.cos(e.t / 55) * 80;
    e.y = e.baseY + Math.sin(e.t / 55) * 46;
  },
  (e) => {
    e.x = e.baseX + Math.sin(e.t / 38 + e.seed) * 130;
    e.y = e.baseY + Math.cos(e.t / 80) * 28;
  },
];

export function bossSpawn(width) {
  return { x: width / 2, y: 130 };
}

// All icons converge to the boss spawn point during morph, with a small
// stagger so they don't sit perfectly on top of each other.
export function computeFormation(count, width, _height) {
  if (count === 0) return [];
  const target = bossSpawn(width);
  const slots = [];
  for (let i = 0; i < count; i++) {
    const offX = (i - (count - 1) / 2) * 9;
    const offY = (i % 3) * 5;
    slots.push({ x: target.x + offX, y: target.y + offY });
  }
  return slots;
}

const KONG_MARK_PATHS =
  '<path d="m11.6089 27.3795.8788-1.1232h6.5031l3.3897 4.2885-.6026 1.455h-8.3863l.2009-1.455z"/>' +
  '<path d="m13.5923 12.7572 3.1401-5.37195h3.6591l16.4012 18.86475-1.2716 5.7502h-7.0328l.4412-1.6141z"/>' +
  '<path d="m17.397 6.36383 1.5035-2.75333 4.5107-3.6105 7.7288 6.00018-1.0023 1.01302 1.3453 1.84421v1.97409l-3.8513 3.117-6.4626-7.58467z"/>' +
  '<path d="m5.45639 18.3602h2.04292l5.32709-4.4124 7.0597 8.1229-1.9912 2.9583h-6.5166l-4.49963 5.666-1.03438 1.3037h-5.84429v-6.9446z"/>';

const KONG_MARK_SVG =
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 32" fill="#0b1f3a">${KONG_MARK_PATHS}</svg>`;

const GORILLA_ART = `          ██████████
        ██▒▒▒▒▒▒▒▒▒▒██
      ██▒▒▒▒  ▒▒▒▒▒▒▒▒▓▓
      ██▒▒  ░░▒▒▒▒▒▒▒▒██
    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    ██▒▒  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    ██▒▒  ▒▒▒▒▒▒▒▒▒▒▓▓▒▒██
    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    ░░▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒██
      ██▒▒▒▒▒▒▒▒▒▒▒▒████
        ██▒▒▓▓▒▒▒▒▓▓██
        ██▓▓▒▒▓▓▓▓████
          ██▓▓▓▓████
          ██████████
            ██████
            ██▓▓██
          ██░░▒▒▓▓██
            ██████
            ▒▒██▒▒
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██
              ██                      ████████████████
              ██                    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒████
              ██                  ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▓
              ██                ██▒▒██████████▓▓▓▓▒▒▒▒▓▓▓▓██
              ██                ████  ░░  ░░░░████▓▓▒▒▒▒▓▓▓▓██
              ██                ██░░░░░░░░░░░░▒▒██▓▓▒▒▒▒▒▒▓▓▓▓██
              ██                ██████░░░░██████████▓▓▒▒████▓▓▓▓██
              ██              ██░░██░░    ░░██░░▒▒██▓▓██░░██▒▒▓▓██
              ██              ██  ░░░░░░░░  ░░░░▒▒████▓▓████▒▒▓▓▓▓██
              ██            ██      ██░░██  ░░  ░░░░████▓▓▒▒▒▒▒▒▓▓████
              ██          ██                  ░░░░░░░░██▒▒▓▓▒▒▒▒████████
              ██          ████████░░    ░░░░░░░░░░░░░░████▓▓▒▒▒▒████▓▓████
              ██          ██░░░░░░░░░░░░░░░░░░░░░░░░▒▒████▒▒▒▒██▓▓▒▒▒▒▓▓████
              ██            ██░░░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓██▓▓
              ██            ██████████████████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓██
              ██          ██▒▒██▓▓▓▓██████████████▓▓▓▓▒▒▓▓▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒████
          ██████        ██▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒██▓▓▓▓▒▒▒▒▒▒▒▒▓▓████
          ██    ██    ██▒▒▒▒▒▒▒▒▒▒▒▒████████████▒▒▓▓▒▒▒▒▒▒▒▒▒▒██▓▓▓▓▒▒▒▒▒▒▒▒▓▓████
        ██░░  ░░░░████▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░░░░░░░████▒▒▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▒▒▒▒▒▒▒▒▓▓████
        ██  ░░░░██████▒▒▒▒▒▒██▒▒▒▒██░░      ░░░░░░████▒▒▒▒▒▒▒▒▓▓████▓▓▓▓▒▒▒▒▒▒▒▒▓▓██
        ██░░░░▒▒██▒▒▒▒██▒▒▓▓██▒▒██░░▒▒░░██  ░░▒▒░░░░██▒▒▓▓▒▒▓▓██████████▒▒▒▒▓▓▒▒▓▓██
          ████████▒▒▒▒▓▓▓▓▓▓██▒▒████████▒▒████████████▒▒▓▓▓▓██████████████▒▒▒▒▒▒▒▒▓▓
          ██▒▒██▒▒▒▒▒▒▓▓▓▓████▓▓▒▒████      ░░██████▓▓▓▓▓▓██▒▒▒▒▒▒▓▓██████▓▓▒▒████▓▓
          ██▒▒██▒▒▒▒▓▓████████▓▓▒▒██    ░░  ░░░░██▓▓▓▓▓▓██▒▒▒▒▒▒▒▒▓▓▓▓████████░░░░██
            ██▒▒▓▓▓▓██████▓▓▓▓██▒▒██      ░░░░░░████▓▓██▒▒▒▒██▒▒▒▒████▓▓████░░░░░░██
          ██  ████████████████▓▓▓▓██    ██░░░░░░████▓▓██▒▒██░░████▓▓██▓▓██░░██░░▒▒██
          ██        ██████░░████▓▓▓▓██░░░░░░░░████▓▓██▒▒▒▒████  ██████████████░░▒▒██
            ██      ██░░████░░██▓▓▓▓██░░░░░░████▓▓▓▓██▒▒▒▒██  ██░░██████    ██░░██
              ██    ████  ░░░░████▓▓▓▓██████████▓▓████▒▒██░░  ░░░░████    ██░░██
                ██    ██░░  ░░██████▓▓▓▓██████████████▒▒██  ░░░░████        ██
  ████          ██      ██░░░░▒▒████████████████████████  ░░▒▒████░░░░░░
██            ██    ░░░░░░██░░▒▒████████████████████████░░▒▒████░░░░░░░░░░░░░░░░
  ████████████        ░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░░░░░░░░░

                            NO AI WITHOUT APIs`;

export class Game {
  constructor(sprites, onExit) {
    this.sprites = sprites;
    this.onExit = onExit;
    this.keys = new Set();
    this.lastTime = 0;
    this.acc = 0;
    this.running = false;
    this.state = "playing";
    this.score = 0;
    this.frame = 0;
    this.enemyAlpha = 0;
    this.minionQueue = [];
    this.bossQueue = [];
    this.bossesDefeated = 0;
    this.stage = 1;
    this.bossInStage = 0;
    this.power = 1;
    this.bombs = BOMB_START;
    this.bombFrames = 0;
    this.lasers = [];
    this.powerups = [];

    this.kongMark = new Image();
    this.kongMark.src = `data:image/svg+xml;base64,${btoa(KONG_MARK_SVG)}`;

    this.gorilla = document.createElement("pre");
    this.gorilla.textContent = GORILLA_ART;
    this.gorilla.style.cssText = [
      "position:fixed",
      "top:50%",
      "right:24px",
      "transform:translateY(-50%)",
      "margin:0",
      "padding:0",
      "z-index:9998",
      "pointer-events:none",
      "user-select:none",
      "white-space:pre",
      "font-family:'JetBrains Mono',ui-monospace,monospace",
      "font-size:11px",
      "line-height:1.4",
      "color:rgba(204,255,0,0.3)",
      "text-shadow:0 0 4px rgba(0,0,0,0.95),0 0 2px rgba(0,0,0,0.95)",
      "letter-spacing:0",
      "max-height:90vh",
      "overflow:hidden",
    ].join(";");

    this.canvas = document.createElement("canvas");
    this.canvas.style.cssText = [
      "position:fixed",
      "inset:0",
      "z-index:9999",
      "background-color:rgba(0,0,0,0)",
      "cursor:none",
    ].join(";");
    this.ctx = this.canvas.getContext("2d");

    this.hud = document.createElement("div");
    this.hud.style.cssText = [
      "position:fixed",
      "inset:0",
      "z-index:10000",
      "pointer-events:none",
      "font-family:'JetBrains Mono',ui-monospace,monospace",
      "color:#ccff00",
      "padding:16px",
      "display:flex",
      "flex-direction:column",
      "justify-content:space-between",
      "opacity:0",
      `transition:opacity ${FADE_IN_MS}ms ease-in`,
    ].join(";");
    const chip = "background:rgba(0,0,0,0.78);padding:6px 10px;border-radius:6px;border:1px solid rgba(204,255,0,0.4)";
    this.hud.innerHTML = `
      <div data-hud="banner" style="position:absolute;top:38%;left:32px;max-width:440px;color:#fff;font-family:'Inter',system-ui,sans-serif;pointer-events:none;transform:translateY(-50%)">
        <h1 style="font-size:40px;font-weight:800;line-height:1.15;margin:0 0 16px 0;color:#fff;text-shadow:0 2px 16px rgba(0,0,0,0.95),0 0 4px rgba(0,0,0,0.9)">Kong Developer</h1>
        <p style="font-size:16px;line-height:1.55;margin:0;opacity:0.95;text-shadow:0 1px 8px rgba(0,0,0,0.95),0 0 2px rgba(0,0,0,0.9)">Discover Kong's tools, APIs, and tutorials to help you build, secure, and scale your services.</p>
      </div>
      <div style="display:flex;justify-content:space-between;gap:12px;font-size:14px">
        <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-start">
          <span data-hud="score" style="${chip}">SCORE 0</span>
          <span data-hud="power" style="${chip}">POWER ●○○○</span>
        </div>
        <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end">
          <span data-hud="bombs" style="${chip}">SPECIAL ATTACK ●●●</span>
          <span style="${chip};opacity:0.85">arrows · Z fire · X special · shift focus · esc exit</span>
        </div>
      </div>
      <div data-hud="overlay" style="text-align:center;font-size:24px"></div>
    `;

    this.resize = () => {
      this.canvas.width = window.innerWidth;
      this.canvas.height = window.innerHeight;
    };
    this.resize();

    this.player = {
      x: this.canvas.width / 2,
      y: this.canvas.height - 90,
      cooldown: 0,
    };

    this.enemies = [];
    this.playerBullets = [];
    this.enemyBullets = [];

    this.onKeyDown = (e) => {
      if (e.key === "Escape") {
        e.preventDefault();
        this.exit();
        return;
      }
      if (e.key === "r" || e.key === "R") {
        if (this.state === "lost") this.restart();
        return;
      }
      if (e.key === "n" || e.key === "N") {
        if (this.state === "stage-clear") this.nextStage();
        return;
      }
      if (e.key === "x" || e.key === "X" || e.key === "b" || e.key === "B") {
        e.preventDefault();
        this.fireBomb();
        return;
      }
      this.keys.add(e.key);
    };
    this.onKeyUp = (e) => this.keys.delete(e.key);
  }

  setSprites(sprites) {
    this.sprites = sprites.length > 0 ? sprites : [makeFallbackSprite()];
    this.startStage(1);
  }

  startStage(stage) {
    this.stage = stage;
    this.bossInStage = 0;
    const count = STAGE_BOSS_COUNTS[stage] || 2;
    const offset = STAGE_BOSS_COUNTS.slice(1, stage).reduce((a, b) => a + b, 0);
    this.bossQueue = [];
    for (let i = 0; i < count; i++) {
      this.bossQueue.push(this.sprites[(offset + i) % this.sprites.length]);
    }
  }

  mountChrome() {
    document.body.appendChild(this.gorilla);
    document.body.appendChild(this.canvas);
    document.body.appendChild(this.hud);
    requestAnimationFrame(() => {
      this.hud.style.opacity = "1";
    });
  }

  spawnNextBoss() {
    if (this.bossQueue.length === 0) return false;
    const sprite = this.bossQueue.shift();
    const seed = Math.floor(Math.random() * 100000);
    const { x, y } = bossSpawn(this.canvas.width);
    const hp =
      BOSS_HP_BASE +
      (this.stage - 1) * STAGE_HP_BONUS +
      this.bossInStage * BOSS_HP_SCALING;
    this.enemies.push({
      kind: "boss",
      sprite,
      x,
      y,
      baseX: x,
      baseY: y,
      hp,
      seed,
      pattern: pickPattern(seed),
      t: 0,
    });
    this.bossInStage++;
    return true;
  }

  spawnMinion() {
    const x = 80 + Math.random() * (this.canvas.width - 160);
    this.enemies.push({
      kind: "minion",
      x,
      y: -30,
      vx: (Math.random() - 0.5) * 1.4,
      vy: MINION_SPEED + Math.random() * 0.5,
      hp: MINION_HP,
      t: 0,
      seed: Math.floor(Math.random() * 100000),
    });
  }

  scheduleMinionWave() {
    const count = 4 + Math.floor(Math.random() * 2);
    for (let i = 0; i < count; i++) {
      this.minionQueue.push(20 + i * 14);
    }
  }

  dropPowerup(x, y) {
    this.powerups.push({
      x,
      y,
      vx: (Math.random() - 0.5) * 0.8,
      vy: 0.8,
    });
  }

  killEnemy(e, index) {
    this.enemies.splice(index, 1);
    if (e.kind === "minion") {
      this.score += 25;
      this.dropPowerup(e.x, e.y);
    } else {
      this.score += 500;
      this.bossesDefeated++;
      this.scheduleMinionWave();
    }
  }

  fireBomb() {
    if (this.state !== "playing") return;
    if (this.bombs <= 0 || this.bombFrames > 0) return;
    this.bombs--;
    this.bombFrames = BOMB_DURATION;
    this.enemyBullets = [];
    const p = this.player;
    this.lasers = [
      { x: p.x - 48, life: BOMB_DURATION, max: BOMB_DURATION },
      { x: p.x, life: BOMB_DURATION, max: BOMB_DURATION },
      { x: p.x + 48, life: BOMB_DURATION, max: BOMB_DURATION },
    ];
  }

  start() {
    this.spawnNextBoss();
    this.enemyAlpha = 0;
    window.addEventListener("keydown", this.onKeyDown);
    window.addEventListener("keyup", this.onKeyUp);
    window.addEventListener("resize", this.resize);
    this.running = true;
    this.lastTime = performance.now();
    requestAnimationFrame(this.loop);
  }

  unmount() {
    this.running = false;
    window.removeEventListener("keydown", this.onKeyDown);
    window.removeEventListener("keyup", this.onKeyUp);
    window.removeEventListener("resize", this.resize);
    this.canvas.remove();
    this.hud.remove();
    this.gorilla.remove();
  }

  exit() {
    this.unmount();
    if (this.onExit) this.onExit();
  }

  restart() {
    this.resetField();
    this.power = 1;
    this.bombs = BOMB_START;
    this.score = 0;
    this.frame = 0;
    this.bossesDefeated = 0;
    this.startStage(1);
    this.state = "playing";
    this.spawnNextBoss();
    this.setOverlay("");
  }

  nextStage() {
    if (this.stage >= STAGES_TOTAL) {
      this.exit();
      return;
    }
    this.resetField();
    this.startStage(this.stage + 1);
    this.state = "playing";
    this.spawnNextBoss();
    this.setOverlay("");
  }

  resetField() {
    this.enemies = [];
    this.playerBullets = [];
    this.enemyBullets = [];
    this.minionQueue = [];
    this.powerups = [];
    this.lasers = [];
    this.bombFrames = 0;
    this.player.x = this.canvas.width / 2;
    this.player.y = this.canvas.height - 90;
    this.player.cooldown = 0;
  }

  loop = (now) => {
    if (!this.running) return;
    this.acc += now - this.lastTime;
    this.lastTime = now;
    let steps = 0;
    while (this.acc >= FIXED_DT && steps < 5) {
      this.tick();
      this.acc -= FIXED_DT;
      steps++;
    }
    this.render();
    requestAnimationFrame(this.loop);
  };

  tick() {
    if (this.enemyAlpha < 1) this.enemyAlpha = Math.min(1, this.enemyAlpha + 0.05);
    if (this.state !== "playing") return;
    this.frame++;

    this.minionQueue = this.minionQueue
      .map((d) => d - 1)
      .filter((d) => {
        if (d <= 0) {
          this.spawnMinion();
          return false;
        }
        return true;
      });

    const focus = this.keys.has("Shift");
    const speed = focus ? PLAYER_FOCUS_SPEED : PLAYER_SPEED;
    let dx = 0;
    let dy = 0;
    if (this.keys.has("ArrowLeft") || this.keys.has("a")) dx -= 1;
    if (this.keys.has("ArrowRight") || this.keys.has("d")) dx += 1;
    if (this.keys.has("ArrowUp") || this.keys.has("w")) dy -= 1;
    if (this.keys.has("ArrowDown") || this.keys.has("s")) dy += 1;
    if (dx && dy) {
      dx *= 0.7071;
      dy *= 0.7071;
    }
    this.player.x = clamp(this.player.x + dx * speed, 16, this.canvas.width - 16);
    this.player.y = clamp(this.player.y + dy * speed, 16, this.canvas.height - 16);

    if (this.player.cooldown > 0) this.player.cooldown--;
    if ((this.keys.has("z") || this.keys.has("Z") || this.keys.has(" ")) && this.player.cooldown === 0) {
      const pattern = POWER_PATTERNS[this.power] || POWER_PATTERNS[1];
      for (const b of pattern) {
        this.playerBullets.push({
          x: this.player.x + b.dx,
          y: this.player.y + b.dy,
          vx: b.vx,
          vy: -PLAYER_BULLET_SPEED,
          r: 4.5,
        });
      }
      this.player.cooldown = PLAYER_FIRE_INTERVAL;
    }

    for (const e of this.enemies) {
      e.t++;
      if (e.kind === "minion") {
        e.x += e.vx;
        e.y += e.vy;
        if (e.t === 22 || e.t === 52) {
          const ax = this.player.x - e.x;
          const ay = this.player.y - e.y;
          const m = Math.hypot(ax, ay) || 1;
          this.enemyBullets.push({
            x: e.x,
            y: e.y,
            vx: (ax / m) * 2.4,
            vy: (ay / m) * 2.4,
            r: 5,
          });
        }
      } else {
        MOVE_FNS[Math.abs(e.seed) % MOVE_FNS.length](e);
        const key = activePattern(e);
        const fn = patterns[key] || patterns[DEFAULT_PATTERN];
        const fresh = fn(e, e.t, this.player);
        for (const b of fresh) this.enemyBullets.push(b);
      }
    }

    for (const b of this.playerBullets) {
      b.x += b.vx;
      b.y += b.vy;
    }
    for (const b of this.enemyBullets) {
      b.x += b.vx;
      b.y += b.vy;
    }

    if (this.bombFrames > 0) {
      this.bombFrames--;
      this.enemyBullets = [];
      for (const laser of this.lasers) {
        for (let j = this.enemies.length - 1; j >= 0; j--) {
          const e = this.enemies[j];
          if (e.y > this.player.y) continue;
          if (Math.abs(e.x - laser.x) < LASER_HALF_WIDTH + (e.kind === "minion" ? 10 : 22)) {
            e.hp--;
            if (e.hp <= 0) this.killEnemy(e, j);
          }
        }
      }
    }
    this.lasers = this.lasers.filter((l) => {
      l.life--;
      return l.life > 0;
    });

    for (let i = this.playerBullets.length - 1; i >= 0; i--) {
      const b = this.playerBullets[i];
      let hit = false;
      for (let j = this.enemies.length - 1; j >= 0; j--) {
        const e = this.enemies[j];
        const hitR = e.kind === "minion" ? MINION_HITBOX : ENEMY_SIZE / 2;
        if (Math.abs(b.x - e.x) < hitR && Math.abs(b.y - e.y) < hitR) {
          e.hp--;
          hit = true;
          if (e.hp <= 0) this.killEnemy(e, j);
          break;
        }
      }
      if (hit) this.playerBullets.splice(i, 1);
    }

    if (this.bombFrames === 0) {
      for (const b of this.enemyBullets) {
        const dxp = b.x - this.player.x;
        const dyp = b.y - this.player.y;
        if (dxp * dxp + dyp * dyp < (PLAYER_HITBOX + b.r) * (PLAYER_HITBOX + b.r)) {
          this.state = "lost";
          this.showMenu("GAME OVER", [
            { label: "RETRY", action: "retry" },
            { label: "BACK TO KONG DEVELOPER", action: "exit" },
          ]);
          return;
        }
      }
    }

    for (let i = this.powerups.length - 1; i >= 0; i--) {
      const pu = this.powerups[i];
      const dxp = this.player.x - pu.x;
      const dyp = this.player.y - pu.y;
      const distSq = dxp * dxp + dyp * dyp;
      if (distSq < POWERUP_MAGNET_RADIUS * POWERUP_MAGNET_RADIUS) {
        const m = Math.sqrt(distSq) || 1;
        pu.vx += (dxp / m) * 0.4;
        pu.vy += (dyp / m) * 0.4;
      }
      pu.vx *= 0.95;
      pu.vy = Math.min(pu.vy * 0.97 + 0.04, 3);
      pu.x += pu.vx;
      pu.y += pu.vy;
      if (distSq < POWERUP_PICKUP_RADIUS * POWERUP_PICKUP_RADIUS) {
        this.powerups.splice(i, 1);
        if (this.power < POWER_MAX) this.power++;
        this.score += 50;
        continue;
      }
      if (pu.y > this.canvas.height + 20) {
        this.powerups.splice(i, 1);
      }
    }

    this.playerBullets = this.playerBullets.filter((b) => onScreen(b, this.canvas));
    this.enemyBullets = this.enemyBullets.filter((b) => onScreen(b, this.canvas));
    this.enemies = this.enemies.filter(
      (e) => e.kind !== "minion" || e.y < this.canvas.height + 40,
    );

    if (
      this.enemies.length === 0 &&
      this.minionQueue.length === 0
    ) {
      if (this.bossQueue.length > 0) {
        this.spawnNextBoss();
      } else if (this.stage < STAGES_TOTAL) {
        this.state = "stage-clear";
        this.showMenu(`STAGE ${this.stage} CLEAR`, [
          { label: "NEXT STAGE →", action: "next" },
          { label: "BACK TO KONG DEVELOPER", action: "exit" },
        ]);
      } else {
        this.state = "won";
        this.showMenu("ALL STAGES COMPLETE ★", [
          { label: "BACK TO KONG DEVELOPER", action: "exit" },
        ]);
      }
    }

    this.updateHud();
  }

  updateHud() {
    this.hud.querySelector('[data-hud="score"]').textContent = `SCORE ${this.score}`;
    const powerStr = "●".repeat(this.power) + "○".repeat(POWER_MAX - this.power);
    this.hud.querySelector('[data-hud="power"]').textContent = `POWER ${powerStr}`;
    const bombStr = this.bombs > 0 ? "●".repeat(this.bombs) : "○";
    this.hud.querySelector('[data-hud="bombs"]').textContent = `SPECIAL ATTACK ${bombStr}`;
  }

  render() {
    const { ctx, canvas } = this;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    ctx.globalAlpha = this.enemyAlpha;
    for (const e of this.enemies) {
      if (e.kind === "minion") {
        ctx.shadowColor = "rgba(0,0,0,0.5)";
        ctx.shadowBlur = 6;
        ctx.fillStyle = "#ffa84a";
        ctx.strokeStyle = "rgba(0,0,0,0.9)";
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.moveTo(e.x, e.y - 10);
        ctx.lineTo(e.x + 10, e.y);
        ctx.lineTo(e.x, e.y + 10);
        ctx.lineTo(e.x - 10, e.y);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
      } else {
        ctx.shadowColor = "rgba(0,0,0,0.5)";
        ctx.shadowBlur = 10;
        if (e.sprite.complete && e.sprite.naturalWidth > 0) {
          ctx.drawImage(e.sprite, e.x - ENEMY_SIZE / 2, e.y - ENEMY_SIZE / 2, ENEMY_SIZE, ENEMY_SIZE);
        } else {
          ctx.fillStyle = "#ccff00";
          ctx.fillRect(e.x - 16, e.y - 16, 32, 32);
        }
      }
    }
    ctx.shadowBlur = 0;
    ctx.globalAlpha = 1;

    this.renderPowerups();
    this.renderLasers();

    ctx.strokeStyle = "rgba(0,0,0,0.85)";
    ctx.lineWidth = 2;
    ctx.fillStyle = "#ccff00";
    for (const b of this.playerBullets) {
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }

    for (const b of this.enemyBullets) {
      ctx.fillStyle = "#ff5577";
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = "#ffaabb";
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r * 0.5, 0, Math.PI * 2);
      ctx.fill();
    }

    this.renderPlayer();

    if (this.keys.has("Shift") && this.state === "playing") {
      ctx.strokeStyle = "#fff";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(this.player.x, this.player.y, PLAYER_HITBOX, 0, Math.PI * 2);
      ctx.stroke();
    }
  }

  renderPowerups() {
    const { ctx } = this;
    for (const pu of this.powerups) {
      const pulse = 1 + Math.sin(this.frame * 0.2) * 0.08;
      ctx.fillStyle = "#33aaff";
      ctx.strokeStyle = "rgba(0,0,0,0.9)";
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.arc(pu.x, pu.y, 9 * pulse, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = "white";
      ctx.font = "bold 11px 'JetBrains Mono', monospace";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText("P", pu.x, pu.y + 1);
    }
  }

  renderLasers() {
    const { ctx } = this;
    const top = 0;
    const bottom = this.player.y - 18;
    for (const laser of this.lasers) {
      const ratio = laser.life / laser.max;
      const fade = ratio < 0.25 ? ratio / 0.25 : 1;
      const flicker = 0.9 + Math.sin(this.frame * 0.5 + laser.x) * 0.1;
      const alpha = fade * flicker;
      ctx.fillStyle = `rgba(204,255,0,${0.22 * alpha})`;
      ctx.fillRect(laser.x - 32, top, 64, bottom - top);
      ctx.fillStyle = `rgba(204,255,0,${0.55 * alpha})`;
      ctx.fillRect(laser.x - LASER_HALF_WIDTH, top, LASER_HALF_WIDTH * 2, bottom - top);
      ctx.fillStyle = `rgba(255,255,255,${0.95 * alpha})`;
      ctx.fillRect(laser.x - 5, top, 10, bottom - top);
    }
  }

  renderPlayer() {
    const { ctx } = this;
    const p = this.player;

    if (this.bombFrames > 0) {
      const aura = 14 + Math.sin(this.frame * 0.5) * 4;
      ctx.fillStyle = `rgba(204,255,0,0.35)`;
      ctx.beginPath();
      ctx.arc(p.x, p.y, aura + 12, 0, Math.PI * 2);
      ctx.fill();
    }

    const glow = ctx.createRadialGradient(p.x, p.y + 18, 0, p.x, p.y + 18, 16);
    glow.addColorStop(0, "rgba(204,255,0,0.55)");
    glow.addColorStop(1, "rgba(204,255,0,0)");
    ctx.fillStyle = glow;
    ctx.fillRect(p.x - 16, p.y + 4, 32, 32);

    ctx.strokeStyle = "rgba(0,0,0,0.9)";
    ctx.lineWidth = 1.5;
    ctx.fillStyle = "rgba(204,255,0,0.78)";
    ctx.beginPath();
    ctx.moveTo(p.x - 17, p.y + 8);
    ctx.lineTo(p.x - 9, p.y - 2);
    ctx.lineTo(p.x - 9, p.y + 14);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(p.x + 17, p.y + 8);
    ctx.lineTo(p.x + 9, p.y - 2);
    ctx.lineTo(p.x + 9, p.y + 14);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    ctx.lineWidth = 2;
    ctx.fillStyle = "#ccff00";
    ctx.beginPath();
    ctx.moveTo(p.x, p.y - 18);
    ctx.lineTo(p.x - 11, p.y + 14);
    ctx.lineTo(p.x + 11, p.y + 14);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    if (this.kongMark.complete && this.kongMark.naturalWidth > 0) {
      const w = 18;
      const h = 14;
      ctx.drawImage(this.kongMark, p.x - w / 2, p.y - h / 2 + 1, w, h);
    } else {
      ctx.fillStyle = "rgba(0,0,0,0.9)";
      ctx.font = "bold 14px 'JetBrains Mono', ui-monospace, monospace";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText("K", p.x, p.y + 3);
    }
  }

  setOverlay(html) {
    const el = this.hud.querySelector('[data-hud="overlay"]');
    el.style.pointerEvents = "none";
    el.innerHTML = html
      ? `<span style="display:inline-block;background:rgba(0,0,0,0.85);padding:12px 18px;border-radius:8px;border:1px solid rgba(204,255,0,0.4)">${html}</span>`
      : "";
    this.canvas.style.cursor = "none";
  }

  showMenu(title, buttons) {
    const el = this.hud.querySelector('[data-hud="overlay"]');
    el.style.pointerEvents = "auto";
    this.canvas.style.cursor = "auto";
    const buttonStyle = [
      "background:rgba(204,255,0,0.16)",
      "color:#ccff00",
      "border:1px solid rgba(204,255,0,0.65)",
      "padding:12px 20px",
      "border-radius:6px",
      "font-family:'JetBrains Mono',ui-monospace,monospace",
      "font-size:14px",
      "font-weight:700",
      "letter-spacing:0.04em",
      "cursor:pointer",
      "pointer-events:auto",
    ].join(";");
    const buttonsHtml = buttons
      .map(
        (b) =>
          `<button data-action="${b.action}" style="${buttonStyle}">${b.label}</button>`,
      )
      .join("");
    el.innerHTML = `
      <div style="display:inline-block;background:rgba(0,0,0,0.88);padding:24px 32px;border-radius:10px;border:1px solid rgba(204,255,0,0.45);text-align:center">
        <div style="font-size:28px;font-weight:700;margin-bottom:8px">${title}</div>
        <div style="font-size:14px;opacity:0.7;margin-bottom:20px">SCORE ${this.score}</div>
        <div style="display:flex;gap:12px;justify-content:center;flex-wrap:wrap">${buttonsHtml}</div>
      </div>
    `;
    el.querySelectorAll("button").forEach((btn) => {
      btn.addEventListener("mouseenter", () => {
        btn.style.background = "rgba(204,255,0,0.32)";
      });
      btn.addEventListener("mouseleave", () => {
        btn.style.background = "rgba(204,255,0,0.16)";
      });
      btn.addEventListener("click", () => {
        const action = btn.getAttribute("data-action");
        if (action === "next") this.nextStage();
        else if (action === "retry") this.restart();
        else if (action === "exit") this.exit();
      });
    });
  }
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

function onScreen(b, canvas) {
  return b.x > -20 && b.x < canvas.width + 20 && b.y > -20 && b.y < canvas.height + 20;
}

function makeFallbackSprite() {
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">` +
    `<rect width="48" height="48" fill="#ccff00"/>` +
    `<g transform="translate(2 6) scale(1.1)" fill="#0b1f3a">${KONG_MARK_PATHS}</g>` +
    `</svg>`;
  const img = new Image();
  img.src = `data:image/svg+xml;base64,${btoa(svg)}`;
  return img;
}
