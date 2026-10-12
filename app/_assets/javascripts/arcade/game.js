import { Sfx } from "./audio";
import { makeSprites } from "./sprites";
import { World } from "./world";
import { Rain, drawPrompt, drawWorld, drawHud, drawBanner } from "./render";

const SCALE = 3;
const STEP = 1 / 120;
const GRAVITY = 2000;
const JUMP_VELOCITY = 720;
const MAX_FALL = 900;
const RUN_SPEED = 280;
const GROUND_ACCEL = 2600;
const AIR_ACCEL = 1600;
const AIR_JUMPS = 1;
const COYOTE_TIME = 0.1;
const JUMP_BUFFER = 0.12;
const DROP_TIME = 0.25;
const PATCH_SECONDS = 1.5;
const PATCH_REACH = 40;
const RAIN_SECONDS = 2.8;
const TYPE_SECONDS = 0.03;
const SPREAD_DELAY = 3;
const HINT_SECONDS = 8;

const STYLE = `
  .arcade-corrupted { filter: hue-rotate(250deg) saturate(2.5) blur(0.6px); opacity: 0.5; transition: filter 0.3s, opacity 0.3s; }
  .arcade-patched { outline: 2px solid #ccff00; outline-offset: 2px; }
  html.arcade-playing, html.arcade-playing body { overscroll-behavior: none; user-select: none; }
`;

const KEYS = {
  left: ["ArrowLeft", "KeyA"],
  right: ["ArrowRight", "KeyD"],
  jump: ["Space", "ArrowUp", "KeyW"],
  down: ["ArrowDown", "KeyS"],
};

// Physical key code, falling back to the key value for synthetic or virtual
// keyboards that leave event.code empty.
function keyCode(event) {
  if (event.code) return event.code;
  if (event.key === " ") return "Space";
  if (/^[a-z]$/i.test(event.key)) return `Key${event.key.toUpperCase()}`;
  return event.key;
}

class Game {
  constructor(onExit) {
    this.onExit = onExit;
    this.state = "rain";
    this.stateTime = 0;
    this.time = 0;
    this.held = new Set();
    this.pressed = new Set();
    this.particles = [];
    this.sprites = makeSprites(SCALE);
    this.scale = SCALE;
    this.initialScroll = { x: window.scrollX, y: window.scrollY };
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    try {
      this.sfx = new Sfx();
    } catch {
      this.sfx = null;
    }

    this.onKeyDown = this.onKeyDown.bind(this);
    this.onKeyUp = this.onKeyUp.bind(this);
    this.onWheel = (event) => event.preventDefault();
    this.onResize = this.onResize.bind(this);
    this.onBlur = () => this.held.clear();
    this.frame = this.frame.bind(this);
  }

  start() {
    this.style = document.createElement("style");
    this.style.textContent = STYLE;
    document.head.appendChild(this.style);

    this.canvas = document.createElement("canvas");
    this.canvas.setAttribute("aria-hidden", "true");
    Object.assign(this.canvas.style, {
      position: "fixed",
      inset: "0",
      zIndex: "2147483000",
      pointerEvents: "none",
      imageRendering: "pixelated",
    });
    document.body.appendChild(this.canvas);
    this.ctx = this.canvas.getContext("2d");
    this.onResize();

    window.addEventListener("keydown", this.onKeyDown, true);
    window.addEventListener("keyup", this.onKeyUp, true);
    window.addEventListener("wheel", this.onWheel, { passive: false });
    window.addEventListener("touchmove", this.onWheel, { passive: false });
    window.addEventListener("resize", this.onResize);
    window.addEventListener("blur", this.onBlur);

    this.rain = new Rain(window.innerWidth, window.innerHeight);
    this.promptLines = [
      "> INTRUSION DETECTED",
      `> ROGUE AGENT LOOSE IN ${window.location.pathname}`,
      "> IT IS REWRITING THE DOCS.",
      "",
      "> SHALL WE PLAY A GAME? [Y/N]",
    ];
    this.promptLength = this.promptLines.join("").length;
    this.typed = 0;
    if (this.reducedMotion) this.setState("prompt");

    this.last = performance.now();
    this.accumulator = 0;
    this.raf = requestAnimationFrame(this.frame);
  }

  exit() {
    cancelAnimationFrame(this.raf);
    window.removeEventListener("keydown", this.onKeyDown, true);
    window.removeEventListener("keyup", this.onKeyUp, true);
    window.removeEventListener("wheel", this.onWheel);
    window.removeEventListener("touchmove", this.onWheel);
    window.removeEventListener("resize", this.onResize);
    window.removeEventListener("blur", this.onBlur);
    this.world?.reset();
    this.canvas.remove();
    this.style.remove();
    document.documentElement.classList.remove("arcade-playing");
    window.scrollTo({ left: this.initialScroll.x, top: this.initialScroll.y, behavior: "instant" });
    this.sfx?.close();
    this.onExit?.();
  }

  setState(state) {
    this.state = state;
    this.stateTime = 0;
  }

  // --- input -------------------------------------------------------------

  onKeyDown(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return;
    // While the game runs it owns the keyboard: no page scrolling, no other
    // shortcuts.
    event.preventDefault();
    event.stopImmediatePropagation();
    this.sfx?.resume();

    const code = keyCode(event);
    if (code === "Escape") return this.exit();
    if (code === "KeyM") this.sfx?.toggleMute();
    if (!event.repeat) this.pressed.add(code);
    this.held.add(code);
  }

  onKeyUp(event) {
    this.held.delete(keyCode(event));
  }

  isHeld(action) {
    return KEYS[action].some((code) => this.held.has(code));
  }

  wasPressed(action) {
    return KEYS[action].some((code) => this.pressed.has(code));
  }

  onResize() {
    const dpr = window.devicePixelRatio || 1;
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = this.width * dpr;
    this.canvas.height = this.height * dpr;
    this.canvas.style.width = `${this.width}px`;
    this.canvas.style.height = `${this.height}px`;
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    this.ctx.imageSmoothingEnabled = false;
    this.world?.layout();
  }

  // --- game setup --------------------------------------------------------

  beginPlay() {
    this.world?.reset();
    this.world = new World();
    this.world.collect();
    document.documentElement.classList.add("arcade-playing");

    if (this.world.platforms.length < 5 || this.world.terminals.length === 0) {
      this.setState("empty");
      return;
    }

    const spawn = this.world.platforms[0];
    this.player = {
      x: spawn.x + 24,
      y: spawn.y - 36,
      w: 24,
      h: 36,
      vx: 0,
      vy: 0,
      facing: 1,
      ground: spawn,
      coyote: 0,
      jumpBuffer: 0,
      airJumps: AIR_JUMPS,
      dropFrom: null,
      dropTime: 0,
    };
    this.camera = Math.max(0, this.player.y - this.height * 0.4);
    this.particles = [];
    this.eye = null;
    this.spreadDelay = SPREAD_DELAY;
    this.hintTime = HINT_SECONDS;
    this.fade = 1;
    this.sfx?.start();
    this.setState("playing");
  }

  terminalPosition(terminal) {
    const p = terminal.platform;
    const width = this.sprites.terminal.ok.width;
    const height = this.sprites.terminal.ok.height;
    return { x: Math.max(p.x, p.x + p.w - width - 24), y: p.y - height + SCALE, width };
  }

  // --- update ------------------------------------------------------------

  frame(now) {
    const dt = Math.min(0.1, (now - this.last) / 1000);
    this.last = now;
    this.time += dt;
    this.stateTime += dt;

    this.accumulator += dt;
    while (this.accumulator >= STEP) {
      this.update(STEP);
      this.pressed.clear();
      this.accumulator -= STEP;
    }

    this.render(dt);
    this.raf = requestAnimationFrame(this.frame);
  }

  update(dt) {
    const anyKey = this.pressed.size > 0;

    if (this.state === "rain") {
      if (anyKey || this.stateTime > RAIN_SECONDS) this.setState("prompt");
    } else if (this.state === "prompt") {
      const done = this.typed >= this.promptLength;
      if (done && (this.pressed.has("KeyY") || this.pressed.has("Enter"))) {
        this.beginPlay();
      } else if (done && this.pressed.has("KeyN")) {
        this.exit();
      } else if (!done && anyKey) {
        this.typed = this.promptLength;
      } else if (!done) {
        const before = Math.floor(this.typed);
        this.typed += dt / TYPE_SECONDS;
        if (Math.floor(this.typed) > before && Math.floor(this.typed) % 2 === 0) this.sfx?.type();
      }
    } else if (this.state === "playing") {
      this.updatePlaying(dt);
    } else if (this.state === "won" || this.state === "lost") {
      if (this.pressed.has("KeyR")) this.beginPlay();
      this.updateParticles(dt);
    } else if (this.state === "empty") {
      if (anyKey) this.exit();
    }
  }

  updatePlaying(dt) {
    const { world, player } = this;
    this.fade = Math.max(0, this.fade - dt * 2);
    this.hintTime -= dt;

    this.updatePlayer(dt);
    this.updateTerminals(dt);

    this.spreadDelay -= dt;
    if (this.spreadDelay <= 0) {
      if (!world.lastInfected) world.seed(3);
      if (world.spread(dt)) this.sfx?.corrupt();
    }

    // If the floor under the player just got corrupted, they fall.
    if (player.ground && !player.ground.floor && player.ground.corrupted && !player.ground.terminal) {
      player.ground = null;
    }

    if (world.lastInfected) {
      const target = { x: world.lastInfected.x + world.lastInfected.w / 2, y: world.lastInfected.y - 40 };
      this.eye ??= { ...target };
      this.eye.x += (target.x - this.eye.x) * Math.min(1, dt * 3);
      this.eye.y += (target.y - this.eye.y) * Math.min(1, dt * 3);
    }

    this.updateParticles(dt);
    this.updateCamera(dt);

    if (world.won()) {
      this.sfx?.win();
      this.burst(player.x + player.w / 2, player.y, "#ccff00", 60);
      this.setState("won");
    } else if (world.lost()) {
      this.sfx?.lose();
      this.setState("lost");
    }
  }

  updatePlayer(dt) {
    const player = this.player;
    const direction = (this.isHeld("right") ? 1 : 0) - (this.isHeld("left") ? 1 : 0);
    const accel = player.ground ? GROUND_ACCEL : AIR_ACCEL;

    if (direction) {
      player.vx += direction * accel * dt;
      player.vx = Math.max(-RUN_SPEED, Math.min(RUN_SPEED, player.vx));
      player.facing = direction;
    } else {
      const slow = accel * dt;
      player.vx = Math.abs(player.vx) <= slow ? 0 : player.vx - Math.sign(player.vx) * slow;
    }

    player.coyote = player.ground ? COYOTE_TIME : player.coyote - dt;
    player.jumpBuffer = this.wasPressed("jump") ? JUMP_BUFFER : player.jumpBuffer - dt;
    player.dropTime -= dt;

    if (player.ground) player.airJumps = AIR_JUMPS;

    // A double jump lets the player climb back over tall paragraphs and code
    // blocks that a single jump can't clear.
    const canJump = player.coyote > 0 || player.airJumps > 0;
    if (player.jumpBuffer > 0 && canJump) {
      if (player.coyote <= 0) {
        player.airJumps -= 1;
        this.burst(player.x + player.w / 2, player.y + player.h, "#ccff00", 8);
      }
      player.vy = -JUMP_VELOCITY;
      player.ground = null;
      player.coyote = 0;
      player.jumpBuffer = 0;
      this.sfx?.jump();
    }
    // Releasing jump early cuts the arc short for finer control.
    if (!this.isHeld("jump") && player.vy < -JUMP_VELOCITY / 2) player.vy = -JUMP_VELOCITY / 2;

    // Down drops through the current ledge, unless standing at a terminal.
    if (this.wasPressed("down") && player.ground && !player.ground.floor && !this.nearbyTerminal()) {
      player.dropFrom = player.ground;
      player.dropTime = DROP_TIME;
      player.ground = null;
      this.sfx?.drop();
    }

    player.vy = Math.min(MAX_FALL, player.vy + GRAVITY * dt);
    const prevBottom = player.y + player.h;
    player.x = Math.max(0, Math.min(document.documentElement.scrollWidth - player.w, player.x + player.vx * dt));
    player.y += player.vy * dt;

    // Keep standing only while still over the ledge.
    if (player.ground && !this.overlapsX(player, player.ground)) player.ground = null;

    if (player.ground) {
      player.y = player.ground.y - player.h;
      player.vy = 0;
      return;
    }

    const bottom = player.y + player.h;
    if (player.vy < 0) return;
    for (const platform of this.world.solids()) {
      if (platform === player.dropFrom && player.dropTime > 0) continue;
      if (prevBottom <= platform.y + 1 && bottom >= platform.y && this.overlapsX(player, platform)) {
        const impact = player.vy;
        player.y = platform.y - player.h;
        player.vy = 0;
        player.ground = platform;
        if (impact > 500) {
          this.sfx?.land();
          this.burst(player.x + player.w / 2, platform.y, "#5c8a00", 6);
        }
        break;
      }
    }
  }

  overlapsX(player, platform) {
    return player.x + player.w > platform.x + 4 && player.x < platform.x + platform.w - 4;
  }

  nearbyTerminal() {
    const player = this.player;
    if (!player.ground) return null;
    return this.world.terminals.find((terminal) => {
      if (terminal.patched || terminal.platform !== player.ground) return false;
      const pos = this.terminalPosition(terminal);
      return Math.abs(player.x + player.w / 2 - (pos.x + pos.width / 2)) < PATCH_REACH;
    });
  }

  updateTerminals(dt) {
    const active = this.isHeld("down") ? this.nearbyTerminal() : null;
    this.world.terminals.forEach((terminal) => {
      if (terminal.patched) return;
      if (terminal === active) {
        const before = Math.floor(terminal.progress * 10);
        terminal.progress += dt / PATCH_SECONDS;
        if (Math.floor(terminal.progress * 10) > before) this.sfx?.patchTick();
        if (terminal.progress >= 1) {
          this.world.patch(terminal);
          this.sfx?.patched();
          const pos = this.terminalPosition(terminal);
          this.burst(pos.x + pos.width / 2, pos.y, "#ccff00", 40);
        }
      } else {
        terminal.progress = Math.max(0, terminal.progress - dt);
      }
    });
  }

  updateCamera(dt) {
    const maxScroll = document.documentElement.scrollHeight - this.height;
    const target = this.player.y + this.player.h / 2 - this.height * 0.5;
    this.camera += (target - this.camera) * Math.min(1, dt * 6);
    this.camera = Math.max(0, Math.min(maxScroll, this.camera));
    window.scrollTo({ left: 0, top: this.camera, behavior: "instant" });
  }

  burst(x, y, color, count) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 80 + Math.random() * 220;
      const life = 0.4 + Math.random() * 0.5;
      this.particles.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 120,
        life,
        maxLife: life,
        color,
      });
    }
  }

  updateParticles(dt) {
    this.particles = this.particles.filter((p) => {
      p.life -= dt;
      p.vy += GRAVITY * 0.4 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      return p.life > 0;
    });
  }

  // --- render ------------------------------------------------------------

  render(dt) {
    const { ctx, width, height } = this;

    if (this.state === "rain") {
      this.rain.draw(ctx, width, height, dt, this.time);
      return;
    }
    if (this.state === "prompt") {
      drawPrompt(ctx, width, height, this.promptLines, Math.floor(this.typed), this.time);
      return;
    }

    ctx.clearRect(0, 0, width, height);
    if (this.state === "empty") {
      drawBanner(ctx, width, height, "NO SIGNAL", ["Not enough docs on this page to play.", "Try a longer page. Press any key."]);
      return;
    }

    drawWorld(ctx, this, this.time);
    drawHud(ctx, this, this.time);

    if (this.fade > 0) {
      ctx.fillStyle = `rgba(0, 0, 0, ${this.fade})`;
      ctx.fillRect(0, 0, width, height);
    }
    if (this.state === "won") {
      drawBanner(ctx, width, height, "AI CONTAINED", ["Every terminal patched. Governance restored.", "R RETRY  ·  ESC EXIT"]);
    } else if (this.state === "lost") {
      drawBanner(
        ctx,
        width,
        height,
        "DOCS COMPROMISED",
        ["The agent rewrote 60% of this page.", "R RETRY  ·  ESC EXIT"],
        "red"
      );
    }
  }
}

export function start({ onExit } = {}) {
  const game = new Game(onExit);
  game.start();
  if (import.meta.env.DEV) window.__arcade = game;
  return game;
}
