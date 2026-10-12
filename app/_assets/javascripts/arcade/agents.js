// Rogue AI agents: red orbs that drift after the player and expire after a
// while. They spawn from the corrupted block nearest the player, come faster
// and more often as the corruption spreads, and corrupt the ledges they pass
// through.

import { RED, clamp } from "./constants";
import { LOSE_RATIO } from "./world";

const RADIUS = 8;
const LIFETIME = 10;
const SPAWN_RANGE = 900;
// Agents spawn at least this far away so the player sees them coming.
const SPAWN_MIN = 300;
const SPAWN_SECONDS = [4, 1.8]; // calm page → nearly lost
const SPEED = [45, 110]; // calm page → nearly lost
// No spawning for this long at the start of a run.
const GRACE = 6;
const INFECT_COOLDOWN = 2;
// Pages with fewer blocks than this get proportionally longer cooldowns.
const INFECT_BLOCKS = 40;

export class Agents {
  // `fx` plays sounds and particle bursts: { sound(name), burst(x, y, color, count) }.
  constructor(fx) {
    this.fx = fx;
    this.orbs = [];
    this.timer = 0;
    // Seconds before spawning resumes (Infinity once the AI is governed).
    this.pause = GRACE;
  }

  // `speed` and `spawnInterval` multiply the base values (plugin modifiers).
  // Calls `onHit(orb)` when an agent reaches a vulnerable player.
  update(dt, { world, player, speed: speedFactor, spawnInterval, onHit }) {
    const ratio = world.corruptionRatio();
    const intensity = Math.min(1, ratio / LOSE_RATIO);
    const px = player.centreX;
    const py = player.centreY;

    this.pause -= dt;
    this.timer -= dt;
    const maxOrbs = 2 + Math.floor(ratio * 10);
    if (this.pause <= 0 && this.timer <= 0 && this.orbs.length < maxOrbs) {
      const source = world.nearestCorrupted(px, py, SPAWN_RANGE, SPAWN_MIN);
      if (source) {
        this.orbs.push({
          x: clamp(px, source.x, source.x + source.w),
          y: source.y,
          vx: 0,
          vy: 0,
          life: LIFETIME,
          infectCooldown: INFECT_COOLDOWN,
          seed: Math.random() * 10,
        });
        const [calm, frantic] = SPAWN_SECONDS;
        this.timer = (calm - (calm - frantic) * intensity) * spawnInterval;
        this.fx.sound("orb");
      }
    }

    const [slow, fast] = SPEED;
    const speed = (slow + (fast - slow) * intensity) * speedFactor;
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
        orb.infectCooldown = INFECT_COOLDOWN * Math.max(1, INFECT_BLOCKS / world.corruptible().length);
        this.fx.sound("corrupt");
        this.fx.burst(orb.x, orb.y, RED, 8);
      }

      if (player.invulnerable <= 0 && distance < RADIUS + player.w / 2 - 4) {
        onHit(orb);
        return false;
      }
      return orb.life > 0;
    });
  }

  // Destroys the half of the agents nearest the player and stops new ones
  // spawning for `pause` seconds.
  deauthenticate(player, pause) {
    const distance = (orb) => Math.hypot(orb.x - player.centreX, orb.y - player.centreY);
    const nearest = [...this.orbs].sort((a, b) => distance(a) - distance(b));
    const destroyed = new Set(nearest.slice(0, Math.ceil(nearest.length / 2)));
    destroyed.forEach((orb) => this.fx.burst(orb.x, orb.y, RED, 10));
    this.orbs = this.orbs.filter((orb) => !destroyed.has(orb));
    this.pause = Math.max(this.pause, pause);
  }

  // Every agent fizzles out and none spawn again.
  clear() {
    this.orbs.forEach((orb) => this.fx.burst(orb.x, orb.y, RED, 10));
    this.orbs = [];
    this.pause = Infinity;
  }
}
