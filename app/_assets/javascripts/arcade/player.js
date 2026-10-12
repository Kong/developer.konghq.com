// The player: running, jumping with one double jump, dropping through
// one-way ledges, and getting knocked back by agents. Positions are document
// coordinates; `ground` is the ledge (or the floor) being stood on.

import { LIME, LIME_DARK, clamp } from "./constants";

const GRAVITY = 2000;
const JUMP_VELOCITY = 720;
const MAX_FALL = 900;
export const RUN_SPEED = 280;
const GROUND_ACCEL = 2600;
const AIR_ACCEL = 1600;
const AIR_JUMPS = 1;
const COYOTE_TIME = 0.1;
const JUMP_BUFFER = 0.12;
const DROP_TIME = 0.25;
const FAST_FALL_DELAY = 0.2;
const WALK_FRAME_PIXELS = 14;
const INVULNERABLE_SECONDS = 2.5;

export class Player {
  // `fx` plays sounds and particle bursts: { sound(name), burst(x, y, color, count) }.
  constructor(spawn, fx) {
    this.fx = fx;
    this.x = spawn.x + 24;
    this.y = spawn.y - 40;
    this.w = 34;
    this.h = 40;
    this.vx = 0;
    this.vy = 0;
    this.facing = 1;
    this.squash = 1;
    this.ground = spawn;
    this.coyote = 0;
    this.jumpBuffer = 0;
    this.airJumps = AIR_JUMPS;
    this.dropFrom = null;
    this.dropTime = 0;
    this.downTime = 0;
    this.invulnerable = 0;
    this.walkPhase = 0;
  }

  get centreX() {
    return this.x + this.w / 2;
  }

  get centreY() {
    return this.y + this.h / 2;
  }

  overlapsX(platform) {
    return this.x + this.w > platform.x + 4 && this.x < platform.x + platform.w - 4;
  }

  update(dt, input, world) {
    const direction = (input.isHeld("right") ? 1 : 0) - (input.isHeld("left") ? 1 : 0);
    const accel = this.ground ? GROUND_ACCEL : AIR_ACCEL;

    if (direction) {
      this.vx += direction * accel * dt;
      this.vx = clamp(this.vx, -RUN_SPEED, RUN_SPEED);
      this.facing = direction;
    } else {
      const slow = accel * dt;
      this.vx = Math.abs(this.vx) <= slow ? 0 : this.vx - Math.sign(this.vx) * slow;
    }

    this.coyote = this.ground ? COYOTE_TIME : this.coyote - dt;
    this.jumpBuffer = input.wasPressed("jump") ? JUMP_BUFFER : this.jumpBuffer - dt;
    this.dropTime -= dt;
    this.invulnerable -= dt;
    this.downTime = input.isHeld("down") ? this.downTime + dt : 0;
    this.squash += (1 - this.squash) * Math.min(1, dt * 12);
    if (this.ground) this.walkPhase += (Math.abs(this.vx) * dt) / WALK_FRAME_PIXELS;
    if (this.ground) this.airJumps = AIR_JUMPS;

    // A double jump lets the player climb back over tall gaps.
    const canJump = this.coyote > 0 || this.airJumps > 0;
    if (this.jumpBuffer > 0 && canJump) {
      if (this.coyote <= 0) {
        this.airJumps -= 1;
        this.fx.burst(this.centreX, this.y + this.h, LIME, 8);
      }
      this.vy = -JUMP_VELOCITY;
      this.ground = null;
      this.coyote = 0;
      this.jumpBuffer = 0;
      this.squash = 1.25;
      this.fx.sound("jump");
    }
    // Releasing jump early cuts the arc short for finer control.
    if (!input.isHeld("jump") && this.vy < -JUMP_VELOCITY / 2) this.vy = -JUMP_VELOCITY / 2;

    // Tap down to drop through one ledge; hold it to keep falling.
    const fastFall = this.downTime >= FAST_FALL_DELAY;
    if ((input.wasPressed("down") || fastFall) && this.ground && !this.ground.floor) {
      this.dropFrom = this.ground;
      this.dropTime = DROP_TIME;
      this.ground = null;
      if (input.wasPressed("down")) this.fx.sound("drop");
    }

    this.vy = Math.min(MAX_FALL, this.vy + GRAVITY * dt);
    const prevBottom = this.y + this.h;
    this.x = clamp(this.x + this.vx * dt, 0, document.documentElement.scrollWidth - this.w);
    this.y += this.vy * dt;

    // Keep standing only while still over the ledge.
    if (this.ground && !this.overlapsX(this.ground)) this.ground = null;

    if (this.ground) {
      this.y = this.ground.y - this.h;
      this.vy = 0;
      return;
    }

    const bottom = this.y + this.h;
    if (this.vy < 0) return;
    for (const platform of world.solids()) {
      if (platform === this.dropFrom && this.dropTime > 0) continue;
      if (fastFall && !platform.floor) continue;
      if (prevBottom <= platform.y + 1 && bottom >= platform.y && this.overlapsX(platform)) {
        const impact = this.vy;
        this.y = platform.y - this.h;
        this.vy = 0;
        this.ground = platform;
        if (impact > 500) {
          this.squash = 0.7;
          this.fx.sound("land");
          this.fx.burst(this.centreX, platform.y, LIME_DARK, 6);
        }
        break;
      }
    }
  }

  // Knocked away from `fromX` and briefly invulnerable.
  knockback(fromX) {
    this.invulnerable = INVULNERABLE_SECONDS;
    this.vx = Math.sign(this.centreX - fromX || 1) * 320;
    this.vy = -420;
    this.ground = null;
  }
}
