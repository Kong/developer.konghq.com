// The level is the current docs page. Block elements become one-way platforms
// (solid from above only), code blocks become terminals, and the footer is the
// floor. All coordinates are document coordinates.

const PLATFORM_SELECTOR =
  "h1, h2, h3, h4, h5, h6, p, li, tr, pre, img, .mermaid, blockquote, figure, hr, .code-block, table";
const MAX_TERMINALS = 6;
const MIN_TERMINALS = 3;
const SAME_TOP = 8;
const PROTECT_RADIUS = 350;
const LOSE_RATIO = 0.6;
const CORRUPTED_CLASS = "arcade-corrupted";
const PATCHED_CLASS = "arcade-patched";

function isVisible(el) {
  const rect = el.getBoundingClientRect();
  if (rect.width < 40 || rect.height < 2) return false;
  return el.checkVisibility ? el.checkVisibility({ visibilityProperty: true }) : true;
}

export class World {
  constructor(root = document.querySelector("main") || document.body) {
    this.root = root;
    this.platforms = [];
    this.terminals = [];
    this.floor = null;
    this.spreadTimer = 0;
    this.spreadInterval = 1;
    this.lastInfected = null;
  }

  collect() {
    const candidates = [...this.root.querySelectorAll(PLATFORM_SELECTOR)].filter(isVisible);
    const tops = new Map(candidates.map((el) => [el, el.getBoundingClientRect().top]));

    // A wrapper whose top edge matches one of its children (table/first row,
    // code-block/pre) would be a duplicate ledge, so keep the child only.
    const elements = candidates.filter(
      (el) =>
        !candidates.some(
          (other) =>
            other !== el && el.contains(other) && Math.abs(tops.get(other) - tops.get(el)) < SAME_TOP
        )
    );

    this.platforms = elements.map((el) => ({
      el,
      x: 0,
      y: 0,
      w: 0,
      h: 0,
      terminal: false,
      corrupted: false,
      protected: false,
    }));
    this.layout();

    this.platforms.sort((a, b) => a.y - b.y || a.x - b.x);
    this.platforms.forEach((platform, index) => (platform.index = index));

    this.pickTerminals();
    this.makeFloor();

    // Give the player enough time to physically reach every terminal on long
    // pages: roughly the run time from top to bottom, plus slack.
    const pageHeight = document.documentElement.scrollHeight;
    const loseSeconds = Math.max(75, (pageHeight / 280) * 1.6 + 30);
    this.spreadInterval = loseSeconds / Math.max(1, this.corruptible().length * LOSE_RATIO);
  }

  layout() {
    const scrollX = window.scrollX;
    const scrollY = window.scrollY;
    this.platforms.forEach((platform) => {
      const rect = platform.el.getBoundingClientRect();
      platform.x = rect.left + scrollX;
      platform.y = rect.top + scrollY;
      platform.w = rect.width;
      platform.h = rect.height;
    });
    if (this.floor) this.makeFloor();
  }

  pickTerminals() {
    let pool = this.platforms.filter((p) => p.el.matches("pre:not(.mermaid)"));
    if (pool.length < MIN_TERMINALS) {
      pool = pool.concat(this.platforms.filter((p) => p.el.matches("h2, h3")));
    }
    // Skip the very first platforms so the player doesn't spawn on a terminal.
    pool = pool.filter((p) => p.index > 1);

    const count = Math.min(MAX_TERMINALS, pool.length);
    const chosen = new Set();
    for (let i = 0; i < count; i++) {
      chosen.add(pool[Math.floor((i * pool.length) / count)]);
    }

    this.terminals = [...chosen].map((platform) => {
      platform.terminal = true;
      return { platform, patched: false, progress: 0 };
    });
  }

  makeFloor() {
    const footer = document.querySelector("footer");
    const pageHeight = document.documentElement.scrollHeight;
    const y = footer ? footer.getBoundingClientRect().top + window.scrollY : pageHeight - 4;
    this.floor = { x: 0, y, w: document.documentElement.scrollWidth, h: 4, floor: true };
  }

  // Platforms the player can land on right now.
  solids() {
    return this.platforms.filter((p) => p.terminal || !p.corrupted).concat(this.floor);
  }

  corruptible() {
    return this.platforms.filter((p) => !p.terminal);
  }

  corruptionRatio() {
    const pool = this.corruptible();
    if (!pool.length) return 0;
    return pool.filter((p) => p.corrupted).length / pool.length;
  }

  lost() {
    return this.corruptionRatio() >= LOSE_RATIO;
  }

  won() {
    return this.terminals.length > 0 && this.terminals.every((t) => t.patched);
  }

  seed(index) {
    const start = this.corruptible().find((p) => p.index >= index);
    if (start) this.infect(start);
  }

  infect(platform) {
    platform.corrupted = true;
    platform.el.classList.add(CORRUPTED_CLASS);
    this.lastInfected = platform;
  }

  // Corruption spreads along the page: each step a random corrupted platform
  // infects one of its nearest neighbours in reading order. Returns the newly
  // infected platform, if any.
  spread(dt) {
    this.spreadTimer += dt;
    if (this.spreadTimer < this.spreadInterval) return null;
    this.spreadTimer = 0;

    const corrupted = this.platforms.filter((p) => p.corrupted);
    for (let attempt = 0; attempt < 8 && corrupted.length; attempt++) {
      const source = corrupted[Math.floor(Math.random() * corrupted.length)];
      const neighbours = [-3, -2, -1, 1, 2, 3]
        .map((offset) => this.platforms[source.index + offset])
        .filter((p) => p && !p.terminal && !p.corrupted && !p.protected);
      if (neighbours.length) {
        const target = neighbours[Math.floor(Math.random() * neighbours.length)];
        this.infect(target);
        return target;
      }
    }
    return null;
  }

  // Patching a terminal cleans and shields everything near it.
  patch(terminal) {
    terminal.patched = true;
    terminal.platform.el.classList.add(PATCHED_CLASS);
    const centre = terminal.platform.y;
    this.platforms.forEach((p) => {
      if (Math.abs(p.y - centre) > PROTECT_RADIUS) return;
      p.protected = true;
      p.corrupted = false;
      p.el.classList.remove(CORRUPTED_CLASS);
    });
  }

  reset() {
    this.platforms.forEach((p) => p.el.classList.remove(CORRUPTED_CLASS, PATCHED_CLASS));
  }
}
