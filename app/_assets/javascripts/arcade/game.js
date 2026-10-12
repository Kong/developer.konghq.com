import { Sfx } from "./audio";
import { CAREERS_URL, formatTime, recordWin } from "./trophy";
import { makeSprites } from "./sprites";
import { World, LOSE_RATIO, FIREWALL } from "./world";
import { Rain, drawPrompt, drawWorld, drawHud, drawMinimap, drawKeybar, drawToast, drawBanner } from "./render";

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
const FAST_FALL_DELAY = 0.2;
const PATCH_SECONDS = 1;
const PATCH_REACH = 48;
const RAIN_SECONDS = 2.8;
const TYPE_SECONDS = 0.025;
const SPREAD_DELAY = 3;
const EXIT_WINDOW = 1.5;
const LIVES = 3;
const INVULNERABLE_SECONDS = 2.5;
const ORB_RADIUS = 8;
const ORB_LIFETIME = 10;
const ORB_SPAWN_RANGE = 900;
// Orbs spawn at least this far away so the player sees them coming.
const ORB_SPAWN_MIN = 300;
const ORB_SPAWN_SECONDS = [4, 1.8]; // calm page → nearly lost
const ORB_GRACE = 6;
const ORB_INFECT_COOLDOWN = 2;
// Pages with fewer blocks than this get proportionally longer orb cooldowns.
const ORB_INFECT_BLOCKS = 40;
// Plugin effects.
const EFFECT_SECONDS = 10;
const DEAUTH_PAUSE = 5;
const ROLLBACK_SHARE = 0.2;
const BOT_SLOWDOWN = 0.5;
const BUDGET_SPREAD = 1.6;
const BUDGET_SPAWN = 1.5;
const WALK_FRAME_PIXELS = 14;
const LOOK_RETURN = 6;
const REACH_CHECK_SECONDS = 0.5;
// How long a terminal can stay cut off before the run is lost.
const CUTOFF_GRACE = 8;
const TOAST_SECONDS = 3;

const STYLE = `
  .arcade-corrupted { filter: hue-rotate(250deg) saturate(2.5) blur(0.6px); opacity: 0.5; transition: filter 0.3s, opacity 0.3s; }
  html.arcade-playing, html.arcade-playing body { overscroll-behavior: none; user-select: none; }
`;

const KEYS = {
  left: ["ArrowLeft", "KeyA"],
  right: ["ArrowRight", "KeyD"],
  jump: ["Space", "ArrowUp", "KeyW"],
  down: ["ArrowDown", "KeyS"],
  use: ["KeyE"],
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
    this.orbs = [];
    this.sprites = makeSprites(SCALE);
    this.scale = SCALE;
    this.maxLives = LIVES;
    this.lastEscape = -Infinity;
    this.initialScroll = { x: window.scrollX, y: window.scrollY };
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    try {
      this.sfx = new Sfx();
    } catch {
      this.sfx = null;
    }

    this.onKeyDown = this.onKeyDown.bind(this);
    this.onKeyUp = this.onKeyUp.bind(this);
    this.onWheel = this.onWheel.bind(this);
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
      `> ROGUE AI AGENT LOOSE IN ${window.location.pathname}`,
      "> IT IS REWRITING THE DOCS.",
      "",
      "> MISSION: REACH EVERY TERMINAL AND ENABLE ITS KONG PLUGIN.",
      `> GOVERN THE AI BEFORE IT CORRUPTS ${LOSE_RATIO * 100}% OF THIS PAGE.`,
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

  toast(title, text, color) {
    this.currentToast = { title, text, color, time: TOAST_SECONDS };
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
    if (code === "Escape") {
      if (event.repeat) return;
      // Esc twice returns to the docs, so a stray press doesn't end a run.
      if (this.state === "empty" || this.exitArmed()) return this.exit();
      this.lastEscape = this.time;
      return;
    }
    if (code === "KeyM" && !event.repeat) this.sfx?.toggleMute();
    if (code === "KeyC" && this.state === "won" && !event.repeat) window.open(CAREERS_URL, "_blank", "noopener");
    if (!event.repeat) this.pressed.add(code);
    this.held.add(code);
  }

  onKeyUp(event) {
    this.held.delete(keyCode(event));
  }

  // The wheel pans the camera to look around the page instead of scrolling
  // it. The view stays put until the player moves again.
  onWheel(event) {
    event.preventDefault();
    if (this.state !== "playing") return;
    const pageHeight = document.documentElement.scrollHeight;
    this.lookOffset = Math.max(-pageHeight, Math.min(pageHeight, this.lookOffset + event.deltaY));
    this.lookReturning = false;
  }

  isHeld(action) {
    return KEYS[action].some((code) => this.held.has(code));
  }

  wasPressed(action) {
    return KEYS[action].some((code) => this.pressed.has(code));
  }

  exitArmed() {
    return this.time - this.lastEscape < EXIT_WINDOW;
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

    if (this.world.segments.length < 5 || this.world.terminals.length === 0) {
      this.setState("empty");
      return;
    }

    const spawn = this.world.segments[0];
    this.player = {
      x: spawn.x + 24,
      y: spawn.y - 40,
      w: 34,
      h: 40,
      vx: 0,
      vy: 0,
      facing: 1,
      squash: 1,
      ground: spawn,
      coyote: 0,
      jumpBuffer: 0,
      airJumps: AIR_JUMPS,
      dropFrom: null,
      dropTime: 0,
      downTime: 0,
      invulnerable: 0,
      walkPhase: 0,
    };
    this.lookOffset = 0;
    this.lookReturning = false;
    this.exitDoor = null;
    this.runTime = 0;
    this.camera = Math.max(0, this.player.y - this.height * 0.4);
    this.lives = LIVES;
    this.particles = [];
    this.orbs = [];
    this.orbTimer = 0;
    this.orbPause = ORB_GRACE;
    // Seconds left on the timed plugin effects.
    this.effects = { slowOrbs: 0, budget: 0 };
    this.eye = null;
    this.spreadDelay = SPREAD_DELAY;
    this.reachTimer = REACH_CHECK_SECONDS;
    this.cutOff = null;
    this.fade = 1;
    this.loseReason = null;
    this.toast("MISSION", `Enable all ${this.world.terminals.length} Kong plugins to govern the rogue AI`);
    this.sfx?.start();
    this.setState("playing");
  }

  terminalPosition(terminal) {
    const segment = terminal.segment;
    const { width, height } = this.sprites.terminal.ok;
    return { x: segment.x + segment.w - width - 16, y: segment.y - height + SCALE, width };
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
    if (this.currentToast) {
      this.currentToast.time -= dt;
      if (this.currentToast.time <= 0) this.currentToast = null;
    }

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
    this.runTime += dt;
    world.tick(dt);
    Object.keys(this.effects).forEach((key) => (this.effects[key] = Math.max(0, this.effects[key] - dt)));
    if (!this.exitDoor) world.spreadMultiplier = this.effects.budget > 0 ? BUDGET_SPREAD : 1;

    this.updatePlayer(dt);
    this.updateTerminals(dt);

    this.spreadDelay -= dt;
    if (this.spreadDelay <= 0) {
      if (!world.lastInfected) world.seed();
      if (world.spread(dt)) this.sfx?.corrupt();
    }

    // If the ledge under the player just got corrupted, they fall.
    if (player.ground && !player.ground.floor && player.ground.corrupted && !player.ground.terminal) {
      player.ground = null;
    }

    if (world.lastInfected) {
      const target = { x: world.lastInfected.x + world.lastInfected.w / 2, y: world.lastInfected.y - 40 };
      this.eye ??= { ...target };
      this.eye.x += (target.x - this.eye.x) * Math.min(1, dt * 3);
      this.eye.y += (target.y - this.eye.y) * Math.min(1, dt * 3);
    }

    this.updateOrbs(dt);
    this.updateParticles(dt);
    this.updateCamera(dt);
    if (this.state !== "playing") return;

    if (this.updateCutOff(dt)) return;

    if (this.exitDoor) {
      if (this.atExit()) {
        this.bestTime = recordWin(this.runTime);
        this.sfx?.win();
        this.burst(player.x + player.w / 2, player.y, "#ccff00", 60);
        this.setState("won");
      }
    } else if (world.allPatched()) {
      this.unlockExit();
    } else if (world.lost()) {
      this.lose("corrupted");
    }
  }

  // With every plugin enabled the AI is governed: corruption clears, the
  // agents fizzle out, and an exit door opens a little further down.
  unlockExit() {
    const { world, player } = this;
    world.cleanseAll();
    world.spreadMultiplier = Infinity;
    this.orbs.forEach((orb) => this.burst(orb.x, orb.y, "#ff2b4f", 10));
    this.orbs = [];
    this.orbPause = Infinity;

    const width = this.sprites.door[0].width;
    const ledge = world.exitLedge(player.y);
    const ground = ledge || world.floor;
    const x = ledge ? ledge.x + (ledge.w - width) / 2 : player.x;
    this.exitDoor = { ground, x, y: ground.y - this.sprites.door[0].height + SCALE, width };
    this.sfx?.win();
    this.toast("EXIT UNLOCKED", "Every plugin enabled. Reach the door further down.");
  }

  atExit() {
    const { player, exitDoor: exit } = this;
    const centre = player.x + player.w / 2;
    return player.ground === exit.ground && centre > exit.x && centre < exit.x + exit.width;
  }

  // A terminal the player can no longer reach starts a countdown with a
  // warning; the run is only lost if it's still cut off when time runs out.
  // Returns true if the run was lost.
  updateCutOff(dt) {
    const { world, player } = this;
    this.reachTimer -= dt;
    if (this.reachTimer <= 0 && player.ground) {
      this.reachTimer = REACH_CHECK_SECONDS;
      const terminal = world.unreachableTerminal(player.ground);
      if (!terminal) {
        if (this.cutOff) this.toast("PATH RESTORED", `${this.cutOff.terminal.plugin.name} is reachable again`);
        this.cutOff = null;
      } else if (this.cutOff?.terminal !== terminal) {
        this.cutOff = { terminal, time: CUTOFF_GRACE };
      }
    }
    if (!this.cutOff) return false;

    this.cutOff.time -= dt;
    const name = this.cutOff.terminal.plugin.name.toUpperCase();
    this.currentToast = {
      title: `${name} CUT OFF`,
      text: `Corruption blocks every route to it. Clear a path in ${Math.ceil(Math.max(0, this.cutOff.time))}s`,
      color: "red",
      time: 1,
    };
    if (this.cutOff.time > 0) return false;
    this.lose("cutoff", this.cutOff.terminal.plugin.name);
    return true;
  }

  lose(reason, detail) {
    this.loseReason = { reason, detail };
    this.sfx?.lose();
    this.setState("lost");
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
    player.invulnerable -= dt;
    player.downTime = this.isHeld("down") ? player.downTime + dt : 0;
    player.squash += (1 - player.squash) * Math.min(1, dt * 12);
    if (player.ground) player.walkPhase += (Math.abs(player.vx) * dt) / WALK_FRAME_PIXELS;
    if (player.ground) player.airJumps = AIR_JUMPS;

    // A double jump lets the player climb back over tall gaps.
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
      player.squash = 1.25;
      this.sfx?.jump();
    }
    // Releasing jump early cuts the arc short for finer control.
    if (!this.isHeld("jump") && player.vy < -JUMP_VELOCITY / 2) player.vy = -JUMP_VELOCITY / 2;

    // Tap down to drop through one ledge; hold it to keep falling.
    const fastFall = player.downTime >= FAST_FALL_DELAY;
    if ((this.wasPressed("down") || fastFall) && player.ground && !player.ground.floor) {
      player.dropFrom = player.ground;
      player.dropTime = DROP_TIME;
      player.ground = null;
      if (this.wasPressed("down")) this.sfx?.drop();
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
      if (fastFall && !platform.floor) continue;
      if (prevBottom <= platform.y + 1 && bottom >= platform.y && this.overlapsX(player, platform)) {
        const impact = player.vy;
        player.y = platform.y - player.h;
        player.vy = 0;
        player.ground = platform;
        if (impact > 500) {
          player.squash = 0.7;
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
    if (!player?.ground) return null;
    return this.world.terminals.find((terminal) => {
      if (terminal.patched || terminal.segment !== player.ground) return false;
      const pos = this.terminalPosition(terminal);
      return Math.abs(player.x + player.w / 2 - (pos.x + pos.width / 2)) < PATCH_REACH;
    });
  }

  updateTerminals(dt) {
    const active = this.isHeld("use") ? this.nearbyTerminal() : null;
    this.world.terminals.forEach((terminal) => {
      if (terminal.patched) return;
      if (terminal === active) {
        const before = Math.floor(terminal.progress * 10);
        terminal.progress += dt / PATCH_SECONDS;
        if (Math.floor(terminal.progress * 10) > before) this.sfx?.patchTick();
        if (terminal.progress >= 1) this.enable(terminal);
      } else {
        terminal.progress = Math.max(0, terminal.progress - dt);
      }
    });
  }

  // Every plugin cleans the area around its terminal, then applies its own
  // effect to the corruption or the agents.
  enable(terminal) {
    const { world } = this;
    const { plugin } = terminal;
    world.patch(terminal, plugin.effect === "firewall" ? FIREWALL : undefined);

    if (plugin.effect === "deauth") {
      this.deauthenticate();
    } else if (plugin.effect === "rollback") {
      world.rollback(ROLLBACK_SHARE);
    } else if (plugin.effect === "slowOrbs" || plugin.effect === "budget") {
      this.effects[plugin.effect] = EFFECT_SECONDS;
    }

    this.sfx?.patched();
    const pos = this.terminalPosition(terminal);
    this.burst(pos.x + pos.width / 2, pos.y, "#ccff00", 40);
    this.toast(`${plugin.name.toUpperCase()} ENABLED`, `${plugin.text} · nearby ledges shielded`);
  }

  // Destroys the half of the agents nearest the player and briefly stops new
  // ones spawning.
  deauthenticate() {
    const { player } = this;
    const distance = (orb) => Math.hypot(orb.x - player.x - player.w / 2, orb.y - player.y - player.h / 2);
    const nearest = [...this.orbs].sort((a, b) => distance(a) - distance(b));
    const destroyed = new Set(nearest.slice(0, Math.ceil(nearest.length / 2)));
    destroyed.forEach((orb) => this.burst(orb.x, orb.y, "#ff2b4f", 10));
    this.orbs = this.orbs.filter((orb) => !destroyed.has(orb));
    this.orbPause = Math.max(this.orbPause, DEAUTH_PAUSE);
  }

  // Seconds left on a plugin's timed effect, for the HUD.
  effectTime(effect) {
    if (effect === "deauth") return Math.max(0, this.orbPause);
    return this.effects?.[effect] || 0;
  }

  // Agents are red orbs that drift after the player and expire after a while.
  // They spawn from the corrupted block nearest the player, and come faster
  // and more often as the corruption spreads.
  updateOrbs(dt) {
    const { world, player } = this;
    const ratio = world.corruptionRatio();
    const intensity = Math.min(1, ratio / LOSE_RATIO);
    const px = player.x + player.w / 2;
    const py = player.y + player.h / 2;

    this.orbPause -= dt;
    this.orbTimer -= dt;
    const maxOrbs = 2 + Math.floor(ratio * 10);
    if (this.orbPause <= 0 && this.orbTimer <= 0 && this.orbs.length < maxOrbs) {
      const source = world.nearestCorrupted(px, py, ORB_SPAWN_RANGE, ORB_SPAWN_MIN);
      if (source) {
        this.orbs.push({
          x: Math.max(source.x, Math.min(source.x + source.w, px)),
          y: source.y,
          vx: 0,
          vy: 0,
          life: ORB_LIFETIME,
          infectCooldown: ORB_INFECT_COOLDOWN,
          seed: Math.random() * 10,
        });
        const [calm, frantic] = ORB_SPAWN_SECONDS;
        const spawnMultiplier = this.effects.budget > 0 ? BUDGET_SPAWN : 1;
        this.orbTimer = (calm - (calm - frantic) * intensity) * spawnMultiplier;
        this.sfx?.orb();
      }
    }

    const speed = (45 + intensity * 65) * (this.effects.slowOrbs > 0 ? BOT_SLOWDOWN : 1);
    this.orbs = this.orbs.filter((orb) => {
      orb.life -= dt;
      const dx = px - orb.x;
      const dy = py - orb.y;
      const distance = Math.hypot(dx, dy) || 1;
      const steer = Math.min(1, dt * 1.5);
      orb.vx += ((dx / distance) * speed - orb.vx) * steer;
      orb.vy += ((dy / distance) * speed - orb.vy) * steer;
      orb.x += orb.vx * dt;
      orb.y += orb.vy * dt;

      // Agents corrupt the ledges they drift through.
      orb.infectCooldown -= dt;
      if (orb.infectCooldown <= 0 && world.infectAt(orb.x, orb.y)) {
        orb.infectCooldown = ORB_INFECT_COOLDOWN * Math.max(1, ORB_INFECT_BLOCKS / world.corruptible().length);
        this.sfx?.corrupt();
        this.burst(orb.x, orb.y, "#ff2b4f", 8);
      }

      if (this.state === "playing" && player.invulnerable <= 0 && distance < ORB_RADIUS + player.w / 2 - 4) {
        this.hurt(orb);
        return false;
      }
      return orb.life > 0;
    });
  }

  hurt(orb) {
    const player = this.player;
    this.lives -= 1;
    player.invulnerable = INVULNERABLE_SECONDS;
    player.vx = Math.sign(player.x + player.w / 2 - orb.x || 1) * 320;
    player.vy = -420;
    player.ground = null;
    this.sfx?.hit();
    this.burst(orb.x, orb.y, "#ff2b4f", 20);
    if (this.lives <= 0) this.lose("caught");
  }

  updateCamera(dt) {
    // Moving, jumping or using a terminal brings the view back to the player.
    const acting = ["left", "right", "jump", "down", "use"].some((action) => this.isHeld(action) || this.wasPressed(action));
    if (acting) this.lookReturning = true;
    if (this.lookReturning) {
      this.lookOffset *= 1 - Math.min(1, dt * LOOK_RETURN);
      if (Math.abs(this.lookOffset) < 1) {
        this.lookOffset = 0;
        this.lookReturning = false;
      }
    }

    const maxScroll = document.documentElement.scrollHeight - this.height;
    const centre = this.player.y + this.player.h / 2 - this.height * 0.5;
    const base = Math.max(0, Math.min(maxScroll, centre));
    // Don't let the offset build up past the page edges.
    this.lookOffset = Math.max(-base, Math.min(maxScroll - base, this.lookOffset));
    const target = base + this.lookOffset;
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
      if (this.exitArmed()) drawKeybar(ctx, width, height, true, this.time);
      return;
    }

    ctx.clearRect(0, 0, width, height);
    if (this.state === "empty") {
      drawBanner(ctx, width, height, "NO SIGNAL", ["Not enough docs on this page to play.", "Try a longer page. Press any key."]);
      return;
    }

    drawWorld(ctx, this, this.time);
    const hudBottom = drawHud(ctx, this, LOSE_RATIO);
    drawMinimap(ctx, this, hudBottom + 16);
    drawKeybar(ctx, width, height, this.exitArmed(), this.time);
    if (this.currentToast && this.state === "playing") drawToast(ctx, width, this.currentToast);

    if (this.fade > 0) {
      ctx.fillStyle = `rgba(0, 0, 0, ${this.fade})`;
      ctx.fillRect(0, 0, width, height);
    }
    if (this.state === "won") {
      drawBanner(ctx, width, height, "AI GOVERNED", [
        "Every Kong plugin enabled. The agent is contained.",
        `TIME ${formatTime(this.runTime)}  ·  BEST ${formatTime(this.bestTime)}`,
        "Good at governing AI? Kong is hiring.",
        "C CAREERS  ·  R RETRY  ·  ESC ×2 EXIT",
      ]);
    } else if (this.state === "lost") {
      drawBanner(ctx, width, height, ...this.loseBanner(), "red");
    }
  }

  loseBanner() {
    const retry = "R RETRY  ·  ESC ×2 EXIT";
    const { reason, detail } = this.loseReason;
    if (reason === "cutoff") {
      return ["TERMINAL CUT OFF", [`The corruption sealed off ${detail}.`, "It can't be reached any more.", retry]];
    }
    if (reason === "caught") return ["AGENT CAUGHT YOU", ["The rogue agents took your last life.", retry]];
    return ["DOCS COMPROMISED", [`The agent rewrote ${LOSE_RATIO * 100}% of this page.`, retry]];
  }
}

export function start({ onExit } = {}) {
  const game = new Game(onExit);
  game.start();
  if (import.meta.env.DEV) window.__arcade = game;
  return game;
}
