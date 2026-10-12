import { track } from "./analytics";
import { Sfx } from "./audio";
import { CAREERS_URL, formatTime, recordWin } from "./trophy";
import { makeSprites } from "./sprites";
import { World, LOSE_RATIO } from "./world";
import { LIME, RED, clamp } from "./constants";
import { Agents } from "./agents";
import { Input, keyCode } from "./input";
import { Particles } from "./particles";
import { Player, RUN_SPEED } from "./player";
import { Rain, drawPrompt, drawBackdrop, drawWorld, drawHud, drawMinimap, drawKeybar, drawToast, drawBanner } from "./render";

const SCALE = 3;
const STEP = 1 / 120;
const PATCH_SECONDS = 1;
const PATCH_REACH = 48;
const RAIN_SECONDS = 2.8;
const TYPE_SECONDS = 0.025;
const SPREAD_DELAY = 3;
const EXIT_WINDOW = 1.5;
const LIVES = 3;
const LOOK_RETURN = 6;
const REACH_CHECK_SECONDS = 0.5;
// How long a terminal can stay cut off before the run is lost.
const CUTOFF_GRACE = 8;
const TOAST_SECONDS = 3;

const STYLE = `
  .arcade-corrupted { filter: hue-rotate(250deg) saturate(2.5) blur(0.6px); opacity: 0.5; transition: filter 0.3s, opacity 0.3s; }
  html.arcade-playing, html.arcade-playing body { overscroll-behavior: none; user-select: none; }
`;

class Game {
  constructor(onExit) {
    this.onExit = onExit;
    this.state = "rain";
    this.stateTime = 0;
    this.time = 0;
    this.input = new Input();
    this.particles = new Particles();
    this.sprites = makeSprites(SCALE);
    this.scale = SCALE;
    this.runSpeed = RUN_SPEED;
    this.maxLives = LIVES;
    this.lastEscape = -Infinity;
    this.initialScroll = { x: window.scrollX, y: window.scrollY };
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    try {
      this.sfx = new Sfx();
    } catch {
      this.sfx = null;
    }
    // What the player and agents use to make noise and sparks.
    this.fx = {
      sound: (name) => this.sfx?.[name](),
      burst: (...args) => this.particles.burst(...args),
    };

    this.onKeyDown = this.onKeyDown.bind(this);
    this.onKeyUp = this.onKeyUp.bind(this);
    this.onWheel = this.onWheel.bind(this);
    // Touch only needs to stop the page scrolling; it has no deltaY to look with.
    this.onTouchMove = (event) => event.preventDefault();
    this.onResize = this.onResize.bind(this);
    // Leaving the window or tab pauses a run, so the AI doesn't win while
    // the player is away. Keys released elsewhere never send keyup here.
    this.onBlur = () => {
      this.input.releaseAll();
      if (this.state === "playing") this.paused = true;
    };
    this.onVisibilityChange = () => document.hidden && this.onBlur();
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
      backdropFilter: "grayscale(1)",
    });
    document.body.appendChild(this.canvas);
    this.ctx = this.canvas.getContext("2d");

    // The canvas is invisible to screen readers, so say what happened and how
    // to get out. Text is set after insertion so it gets announced.
    this.announcer = document.createElement("div");
    this.announcer.className = "sr-only";
    this.announcer.setAttribute("role", "status");
    document.body.appendChild(this.announcer);
    setTimeout(() => (this.announcer.textContent = "Docs arcade started. Press Escape twice to exit."), 100);
    this.onResize();

    window.addEventListener("keydown", this.onKeyDown, true);
    window.addEventListener("keyup", this.onKeyUp, true);
    window.addEventListener("wheel", this.onWheel, { passive: false });
    window.addEventListener("touchmove", this.onTouchMove, { passive: false });
    window.addEventListener("resize", this.onResize);
    window.addEventListener("blur", this.onBlur);
    document.addEventListener("visibilitychange", this.onVisibilityChange);

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
    if (this.exited) return;
    // frame() checks this too: exit() can run mid-frame, after the current
    // frame's callback has already fired, so cancelling it isn't enough.
    this.exited = true;
    if (this.state === "playing") this.trackEnd("quit");
    cancelAnimationFrame(this.raf);
    window.removeEventListener("keydown", this.onKeyDown, true);
    window.removeEventListener("keyup", this.onKeyUp, true);
    window.removeEventListener("wheel", this.onWheel);
    window.removeEventListener("touchmove", this.onTouchMove);
    window.removeEventListener("resize", this.onResize);
    window.removeEventListener("blur", this.onBlur);
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
    this.world?.reset();
    this.canvas.remove();
    this.announcer.remove();
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
      // Before a run starts one Esc exits; during a run it takes two, so a
      // stray press doesn't end it.
      if (["rain", "prompt", "empty"].includes(this.state) || this.exitArmed()) return this.exit();
      this.lastEscape = this.time;
      return;
    }
    if (code === "KeyM" && !event.repeat) this.sfx?.toggleMute();
    if (code === "KeyP" && !event.repeat && this.state === "playing") this.paused = !this.paused;
    if (code === "KeyC" && this.state === "won" && !event.repeat) {
      track("Arcade Careers Clicked", { source: "win-screen" });
      window.open(CAREERS_URL, "_blank", "noopener,noreferrer");
    }
    this.input.press(code, event.repeat);
  }

  onKeyUp(event) {
    this.input.release(keyCode(event));
  }

  // The wheel pans the camera to look around the page instead of scrolling
  // it. The view stays put until the player moves again.
  onWheel(event) {
    event.preventDefault();
    if (this.state !== "playing" || this.paused) return;
    const pageHeight = document.documentElement.scrollHeight;
    this.lookOffset = clamp(this.lookOffset + event.deltaY, -pageHeight, pageHeight);
    this.lookReturning = false;
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
    if (!this.world) return;

    // Ledges move and resize with the page, so carry the player and the exit
    // door along with the ledge they stand on.
    const { player } = this;
    const ground = player?.ground;
    const along = ground && (player.x - ground.x) / ground.w;
    this.world.layout();
    if (ground) {
      player.x = ground.x + along * ground.w;
      player.y = ground.y - player.h;
    }
    if (this.exitDoor) this.placeDoor(this.exitDoor.ground, this.exitDoor.ground.floor ? this.exitDoor.x : null);
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

    this.player = new Player(this.world.segments[0], this.fx);
    this.lookOffset = 0;
    this.lookReturning = false;
    this.paused = false;
    this.exitDoor = null;
    this.runTime = 0;
    this.camera = Math.max(0, this.player.y - this.height * 0.4);
    this.lives = LIVES;
    this.particles = new Particles();
    this.agents = new Agents(this.fx);
    // Seconds left on each running timed plugin effect, keyed by plugin.
    this.effects = new Map();
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
    while (this.accumulator >= STEP && !this.exited) {
      this.update(STEP);
      this.input.endStep();
      this.accumulator -= STEP;
    }
    if (this.exited) return;

    // Scroll once per frame, not once per physics step.
    if (this.state === "playing") window.scrollTo({ left: 0, top: this.camera, behavior: "instant" });
    this.render(dt);
    this.raf = requestAnimationFrame(this.frame);
  }

  update(dt) {
    // Paused freezes the run: no world, agents, timers or toasts. Keys that
    // still work while paused (P, M, Esc) are handled in onKeyDown.
    if (this.paused) return;
    const anyKey = this.input.anyPressed();
    if (this.currentToast) {
      this.currentToast.time -= dt;
      if (this.currentToast.time <= 0) this.currentToast = null;
    }

    if (this.state === "rain") {
      if (anyKey || this.stateTime > RAIN_SECONDS) this.setState("prompt");
    } else if (this.state === "prompt") {
      const done = this.typed >= this.promptLength;
      if (done && (this.input.pressed.has("KeyY") || this.input.pressed.has("Enter"))) {
        track("Arcade Played");
        this.beginPlay();
      } else if (done && this.input.pressed.has("KeyN")) {
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
      if (this.input.pressed.has("KeyR")) this.beginPlay();
      this.particles.update(dt);
    } else if (this.state === "empty") {
      if (anyKey) this.exit();
    }
  }

  updatePlaying(dt) {
    const { world, player } = this;
    this.fade = Math.max(0, this.fade - dt * 2);
    this.runTime += dt;
    world.tick(dt);
    this.effects.forEach((seconds, plugin) => {
      if (seconds <= dt) this.effects.delete(plugin);
      else this.effects.set(plugin, seconds - dt);
    });
    if (!this.exitDoor) world.spreadMultiplier = this.modifier("spreadInterval");

    player.update(dt, this.input, world);
    this.updateTerminals(dt);

    // Corruption seeds itself once the delay runs out: at the start of a run,
    // and again if plugins ever clear the whole page (see enable()).
    this.spreadDelay -= dt;
    if (this.spreadDelay <= 0 && !this.exitDoor) {
      if (!world.anyCorrupted()) world.seed();
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

    this.agents.update(dt, {
      world,
      player,
      speed: this.modifier("orbSpeed"),
      spawnInterval: this.modifier("spawnInterval"),
      onHit: (orb) => this.hurt(orb),
    });
    this.particles.update(dt);
    this.updateCamera(dt);
    if (this.state !== "playing") return;

    if (this.updateCutOff(dt)) return;

    if (this.exitDoor) {
      if (this.atExit()) {
        this.bestTime = recordWin(this.runTime);
        this.trackEnd("won");
        this.sfx?.win();
        this.particles.burst(player.centreX, player.y, LIME, 60);
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
    this.agents.clear();

    const ledge = world.exitLedge(player.y);
    this.placeDoor(ledge || world.floor, ledge ? null : player.x);
    this.sfx?.win();
    this.toast("EXIT UNLOCKED", "Every plugin enabled. Reach the door further down.");
  }

  // Centred on a ledge, or at `x` on the floor.
  placeDoor(ground, x = null) {
    const { width, height } = this.sprites.door[0];
    this.exitDoor = {
      ground,
      x: x ?? ground.x + (ground.w - width) / 2,
      y: ground.y - height + SCALE,
      width,
    };
  }

  atExit() {
    const { player, exitDoor: exit } = this;
    const centre = player.centreX;
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
    this.trackEnd("lost", reason);
    this.sfx?.lose();
    this.setState("lost");
  }

  trackEnd(outcome, reason = null) {
    track("Arcade Ended", { outcome, reason, seconds: Math.round(this.runTime) });
  }

  nearbyTerminal() {
    const player = this.player;
    if (!player?.ground) return null;
    return this.world.terminals.find((terminal) => {
      if (terminal.patched || terminal.segment !== player.ground) return false;
      const pos = this.terminalPosition(terminal);
      return Math.abs(player.centreX - (pos.x + pos.width / 2)) < PATCH_REACH;
    });
  }

  updateTerminals(dt) {
    const active = this.input.isHeld("use") ? this.nearbyTerminal() : null;
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
  // effect (see plugins.js).
  enable(terminal) {
    const { plugin } = terminal;
    this.world.patch(terminal, plugin.shield);
    if (plugin.seconds) this.effects.set(plugin, plugin.seconds);
    plugin.enable?.(this);
    // A clean page gets the same breather as the start of a run, then the AI
    // comes back. Without this a small page could stay clean for good.
    if (!this.world.anyCorrupted()) this.spreadDelay = SPREAD_DELAY;

    this.sfx?.patched();
    const pos = this.terminalPosition(terminal);
    this.particles.burst(pos.x + pos.width / 2, pos.y, LIME, 40);
    this.toast(`${plugin.name.toUpperCase()} ENABLED`, `${plugin.text} · nearby ledges shielded`);
  }

  // The product of a named modifier across running plugin effects, so
  // overlapping effects stack. 1 when none applies.
  modifier(name) {
    let value = 1;
    this.effects.forEach((_, plugin) => (value *= plugin.modifiers?.[name] ?? 1));
    return value;
  }

  // Seconds left on a plugin's effect, for the HUD.
  effectTime(plugin) {
    return plugin.remaining?.(this) ?? this.effects?.get(plugin) ?? 0;
  }

  hurt(orb) {
    this.lives -= 1;
    this.player.knockback(orb.x);
    this.sfx?.hit();
    this.particles.burst(orb.x, orb.y, RED, 20);
    if (this.lives <= 0) this.lose("caught");
  }

  updateCamera(dt) {
    // Moving, jumping or using a terminal brings the view back to the player.
    const { input } = this;
    const acting = ["left", "right", "jump", "down", "use"].some(
      (action) => input.isHeld(action) || input.wasPressed(action)
    );
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
    const base = clamp(centre, 0, maxScroll);
    // Don't let the offset build up past the page edges.
    this.lookOffset = clamp(this.lookOffset, -base, maxScroll - base);
    const target = base + this.lookOffset;
    this.camera += (target - this.camera) * Math.min(1, dt * 6);
    this.camera = clamp(this.camera, 0, maxScroll);
  }

  // --- render ------------------------------------------------------------

  render(dt) {
    const { ctx, width, height } = this;
    // Reduced motion freezes the animation clock, so nothing flashes or
    // flickers. Movement and physics are unaffected.
    const time = this.reducedMotion ? 0 : this.time;

    if (this.state === "rain") {
      this.rain.draw(ctx, width, height, dt, time);
      return;
    }
    if (this.state === "prompt") {
      drawPrompt(ctx, width, height, this.promptLines, Math.floor(this.typed), time);
      return;
    }

    ctx.clearRect(0, 0, width, height);
    if (this.state === "empty") {
      drawBanner(ctx, width, height, "NO SIGNAL", ["Not enough docs on this page to play.", "Try a longer page. Press any key."]);
      return;
    }

    drawBackdrop(ctx, width, height);
    drawWorld(ctx, this, time);
    if (this.paused) {
      drawHud(ctx, this, { centred: true });
      drawKeybar(ctx, width, height, { exitArmed: this.exitArmed(), paused: true }, time);
      return;
    }
    const hudBottom = drawHud(ctx, this);
    drawMinimap(ctx, this, hudBottom + 16, time);
    drawKeybar(ctx, width, height, { exitArmed: this.exitArmed() }, time);
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
