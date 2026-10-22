// Short-lived pixel sparks for jumps, landings, hits and plugin bursts.

const GRAVITY = 800;

export class Particles {
  constructor() {
    this.items = [];
  }

  burst(x, y, color, count) {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 80 + Math.random() * 220;
      const life = 0.4 + Math.random() * 0.5;
      this.items.push({
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

  update(dt) {
    this.items = this.items.filter((p) => {
      p.life -= dt;
      p.vy += GRAVITY * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      return p.life > 0;
    });
  }
}
