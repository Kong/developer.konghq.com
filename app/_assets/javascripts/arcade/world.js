// The level is generated from the current docs page. Block elements anchor
// chunky one-way ledges (solid from above only), code blocks host terminals,
// and the footer is the floor. All coordinates are document coordinates.

const BLOCK_SELECTOR =
  "h1, h2, h3, h4, h5, h6, p, li, tr, pre, img, .mermaid, blockquote, figure, hr, .code-block, table";
const SAME_TOP = 8;
const MIN_GAP = 64;
const MAX_GAP = 150;
const LEDGE_WIDTH = [150, 300];
const FILLER_WIDTH = [96, 150];
const HOP = [120, 240];
const TERMINAL_WIDTH = 200;
const TWIN_CHANCE = 0.25;
const MAX_TERMINALS = 6;
const MIN_TERMINALS = 3;
const PROTECT_RADIUS = 350;
// Lift ledges into the margin above their block so they don't cover text.
const LIFT = 10;
const CORRUPTED_CLASS = "arcade-corrupted";
const PATCHED_CLASS = "arcade-patched";

export const LOSE_RATIO = 0.6;
// Generous estimates of what a double jump can clear. Used to decide when a
// terminal has been cut off for good.
export const UP_REACH = 250;
export const SIDE_REACH = 260;
const FALL_WINDOW = 800;

export const PLUGINS = [
  { name: "Rate Limiting", effect: "throttle", text: "Corruption throttled" },
  { name: "AI Prompt Guard", effect: "firewall", text: "Firewall up: wide area shielded" },
  { name: "OpenID Connect", effect: "deauth", text: "Rogue agents de-authenticated" },
  { name: "AI Semantic Prompt Guard", effect: "rollback", text: "Semantic rollback: corruption reversed" },
  { name: "Bot Detection", effect: "slowOrbs", text: "Bots detected: agents slowed" },
  { name: "AI Rate Limiting Advanced", effect: "budget", text: "Token budget enforced" },
];

function isVisible(el) {
  const rect = el.getBoundingClientRect();
  if (rect.width < 40 || rect.height < 2) return false;
  return el.checkVisibility ? el.checkVisibility({ visibilityProperty: true }) : true;
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

// Same page, same level: seed the generator from the URL path.
function seededRandom(text) {
  let seed = 0;
  for (const char of text) seed = (Math.imul(seed, 31) + char.charCodeAt(0)) | 0;
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function horizontalGap(a, b) {
  return Math.max(0, Math.max(a.x, b.x) - Math.min(a.x + a.w, b.x + b.w));
}

// First index in a y-sorted list whose y is at least `y`.
function lowerBound(nodes, y) {
  let lo = 0;
  let hi = nodes.length;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (nodes[mid].y < y) lo = mid + 1;
    else hi = mid;
  }
  return lo;
}

function canReach(from, to) {
  const gap = horizontalGap(from, to);
  const rise = from.y - to.y;
  if (rise > 0) return rise <= UP_REACH && gap <= SIDE_REACH;
  // Falling buys extra air time, so lower ledges can be further away.
  return gap <= SIDE_REACH - rise * 0.6;
}

export class World {
  constructor(root = document.querySelector("main") || document.body) {
    this.root = root;
    this.random = seededRandom(window.location.pathname);
    this.segments = [];
    this.terminals = [];
    this.byElement = new Map();
    this.floor = null;
    this.spreadTimer = 0;
    this.spreadInterval = 1;
    this.spreadMultiplier = 1;
    this.lastInfected = null;
  }

  // --- generation ----------------------------------------------------------

  collectBlocks() {
    const candidates = [...this.root.querySelectorAll(BLOCK_SELECTOR)].filter(isVisible);
    const rects = new Map(candidates.map((el) => [el, el.getBoundingClientRect()]));

    // A wrapper whose top edge matches one of its children (table/first row,
    // code-block/pre) would be a duplicate anchor, so keep the child only.
    const elements = candidates.filter(
      (el) =>
        !candidates.some(
          (other) => other !== el && el.contains(other) && Math.abs(rects.get(other).top - rects.get(el).top) < SAME_TOP
        )
    );

    return elements
      .map((el) => {
        const rect = rects.get(el);
        return { el, x: rect.left + window.scrollX, y: rect.top + window.scrollY, w: rect.width };
      })
      .sort((a, b) => a.y - b.y || a.x - b.x);
  }

  collect() {
    this.measureColumn();
    this.makeFloor();
    const blocks = this.collectBlocks();
    if (blocks.length < 5) return;

    this.build(blocks, this.pickTerminalBlocks(blocks));

    this.segments.sort((a, b) => a.y - b.y || a.x - b.x);
    this.segments.forEach((segment, index) => {
      segment.index = index;
      if (!this.byElement.has(segment.el)) this.byElement.set(segment.el, []);
      this.byElement.get(segment.el).push(segment);
    });

    this.terminals = this.segments
      .filter((segment) => segment.terminal)
      .map((segment, i) => ({ segment, plugin: PLUGINS[i], patched: false, progress: 0 }));

    // Give the player enough time to physically reach every terminal on long
    // pages: roughly the run time from top to bottom, plus slack.
    const pageHeight = document.documentElement.scrollHeight;
    const loseSeconds = Math.max(75, (pageHeight / 280) * 1.6 + 30);
    this.spreadInterval = loseSeconds / Math.max(1, this.corruptible().length * LOSE_RATIO);
  }

  pickTerminalBlocks(blocks) {
    let pool = blocks.filter((b) => b.el.matches("pre:not(.mermaid)"));
    if (pool.length < MIN_TERMINALS) pool = pool.concat(blocks.filter((b) => b.el.matches("h2, h3")));
    // Skip the first blocks so the player doesn't spawn on a terminal.
    pool = pool.filter((b) => blocks.indexOf(b) > 1).sort((a, b) => a.y - b.y);

    const count = Math.min(MAX_TERMINALS, pool.length);
    const chosen = new Set();
    for (let i = 0; i < count; i++) chosen.add(pool[Math.floor((i * pool.length) / count)]);
    return chosen;
  }

  build(blocks, terminalBlocks) {
    const terminalTops = [...terminalBlocks].map((b) => b.y);
    const first = blocks[0];
    let prev = this.addSegment(first, first.x, Math.min(260, first.w), 0, "ledge");

    for (const block of blocks.slice(1)) {
      const isTerminal = terminalBlocks.has(block);
      if (!isTerminal) {
        if (block.y - prev.y < MIN_GAP) continue;
        // Leave headroom above terminals.
        if (terminalTops.some((top) => top > block.y && top - block.y < MIN_GAP)) continue;
      }

      // Fill tall gaps with floating ledges so every step stays climbable.
      const baseY = prev.y;
      const gap = block.y - baseY;
      const steps = Math.ceil(gap / MAX_GAP);
      for (let step = 1; step < steps; step++) {
        const y = baseY + (gap * step) / steps;
        prev = this.hop(prev, block, y - block.y, FILLER_WIDTH, this.left, this.right, "filler");
      }

      if (isTerminal) {
        const width = Math.min(TERMINAL_WIDTH, block.w);
        const x = Math.min(block.x + block.w, this.right) - width;
        prev = this.bridge(prev, x, width, block, 0);
        prev = this.addSegment(block, x, width, 0, "terminal");
      } else {
        const lo = Math.max(this.left, block.x);
        const hi = Math.min(this.right, block.x + block.w);
        prev = this.hop(prev, block, 0, LEDGE_WIDTH, lo, hi, "ledge");
        if (this.random() < TWIN_CHANCE) this.twin(prev, block, lo, hi);
      }
    }

    // Keep stepping down to the floor so the player can always climb back up.
    const last = blocks[blocks.length - 1];
    const baseY = prev.y;
    const gap = this.floor.y - baseY;
    const steps = Math.ceil(gap / MAX_GAP);
    for (let step = 1; step < steps; step++) {
      const y = baseY + (gap * step) / steps;
      prev = this.hop(prev, last, y - last.y, FILLER_WIDTH, this.left, this.right, "filler");
    }
  }

  // Place a ledge a short hop left or right of the previous one.
  hop(prev, block, dy, [minWidth, maxWidth], lo, hi, kind) {
    const width = Math.min(hi - lo, minWidth + this.random() * (maxWidth - minWidth));
    const prevCentre = prev.x + prev.w / 2;
    const distance = HOP[0] + this.random() * (HOP[1] - HOP[0]);
    let direction = this.random() < 0.5 ? -1 : 1;
    let centre = prevCentre + direction * distance;
    if (centre - width / 2 < lo || centre + width / 2 > hi) {
      direction = -direction;
      centre = prevCentre + direction * distance;
    }
    const x = clamp(centre - width / 2, lo, hi - width);
    prev = this.bridge(prev, x, width, block, dy);
    return this.addSegment(block, x, width, dy, kind);
  }

  // Add stepping stones when the next ledge is out of horizontal reach.
  bridge(prev, x, width, block, dy) {
    const target = { x, w: width };
    const targetY = block.y + dy;
    for (let guard = 0; guard < 6 && horizontalGap(prev, target) > SIDE_REACH * 0.8; guard++) {
      const fillerWidth = FILLER_WIDTH[0];
      const towards = x > prev.x ? 1 : -1;
      const fx = towards > 0 ? prev.x + prev.w + SIDE_REACH * 0.5 : prev.x - SIDE_REACH * 0.5 - fillerWidth;
      const fy = prev.y + (targetY - prev.y) / 2;
      prev = this.addSegment(block, clamp(fx, this.left, this.right - fillerWidth), fillerWidth, fy - block.y, "filler");
    }
    return prev;
  }

  // Sometimes add a second ledge on the same row, on the other side.
  twin(ledge, block, lo, hi) {
    const width = LEDGE_WIDTH[0];
    const spacing = 100 + this.random() * 100;
    const leftX = ledge.x - spacing - width;
    const rightX = ledge.x + ledge.w + spacing;
    if (rightX + width <= hi) this.addSegment(block, rightX, width, 0, "ledge");
    else if (leftX >= lo) this.addSegment(block, leftX, width, 0, "ledge");
  }

  addSegment(block, x, w, dy, kind) {
    const segment = {
      el: block.el,
      kind,
      // Positions are stored relative to the anchor element and column so the
      // level survives a resize.
      fx: (x - this.left) / Math.max(1, this.right - this.left),
      dy: dy - LIFT,
      x,
      y: block.y + dy - LIFT,
      w,
      terminal: kind === "terminal",
      corrupted: false,
      protected: false,
    };
    this.segments.push(segment);
    return segment;
  }

  measureColumn() {
    const rect = this.root.getBoundingClientRect();
    this.left = Math.max(0, rect.left) + window.scrollX;
    this.right = rect.right + window.scrollX;
  }

  layout() {
    this.measureColumn();
    this.segments.forEach((segment) => {
      const rect = segment.el.getBoundingClientRect();
      segment.y = rect.top + window.scrollY + segment.dy;
      segment.x = clamp(this.left + segment.fx * (this.right - this.left), this.left, this.right - segment.w);
    });
    this.makeFloor();
  }

  makeFloor() {
    const footer = document.querySelector("footer");
    const pageHeight = document.documentElement.scrollHeight;
    const y = footer ? footer.getBoundingClientRect().top + window.scrollY : pageHeight - 4;
    this.floor = { x: 0, y, w: document.documentElement.scrollWidth, floor: true };
  }

  // --- queries -------------------------------------------------------------

  // Ledges the player can land on right now.
  solids() {
    return this.segments.filter((s) => s.terminal || !s.corrupted).concat(this.floor);
  }

  corruptible() {
    return this.segments.filter((s) => !s.terminal);
  }

  corruptionRatio() {
    const pool = this.corruptible();
    if (!pool.length) return 0;
    return pool.filter((s) => s.corrupted).length / pool.length;
  }

  lost() {
    return this.corruptionRatio() >= LOSE_RATIO;
  }

  won() {
    return this.terminals.length > 0 && this.terminals.every((t) => t.patched);
  }

  // Walks every jump the player could still make from `start` and returns the
  // first unpatched terminal that can no longer be reached, if any.
  // Only nearby ledges are considered: a long fall lands on the first ledge
  // underneath anyway, and the floor is always reachable.
  unreachableTerminal(start) {
    const nodes = this.segments.filter((s) => s.terminal || !s.corrupted);
    const seen = new Set([start, this.floor]);
    const queue = [start, this.floor];
    while (queue.length) {
      const from = queue.pop();
      const top = from.y - UP_REACH;
      const bottom = from.floor ? Infinity : from.y + FALL_WINDOW;
      for (let i = lowerBound(nodes, top); i < nodes.length && nodes[i].y <= bottom; i++) {
        const to = nodes[i];
        if (seen.has(to) || !canReach(from, to)) continue;
        seen.add(to);
        queue.push(to);
      }
    }
    return this.terminals.find((t) => !t.patched && !seen.has(t.segment));
  }

  nearestCorrupted(x, y, maxDistance) {
    let best = null;
    let bestDistance = maxDistance;
    this.segments.forEach((s) => {
      if (!s.corrupted) return;
      const distance = Math.hypot(s.x + s.w / 2 - x, s.y - y);
      if (distance < bestDistance) {
        best = s;
        bestDistance = distance;
      }
    });
    return best;
  }

  // --- corruption ----------------------------------------------------------

  syncClasses(el) {
    const segments = this.byElement.get(el) || [];
    el.classList.toggle(CORRUPTED_CLASS, segments.some((s) => s.kind !== "filler" && s.corrupted));
  }

  seed(index) {
    const start = this.corruptible().find((s) => s.index >= index);
    if (start) this.infect(start);
  }

  infect(segment) {
    segment.corrupted = true;
    this.syncClasses(segment.el);
    this.lastInfected = segment;
  }

  cleanse(segment) {
    segment.corrupted = false;
    this.syncClasses(segment.el);
  }

  // Corruption spreads along the page: each step a random corrupted ledge
  // infects one of its nearest neighbours in reading order. Returns the newly
  // infected ledge, if any.
  spread(dt) {
    this.spreadTimer += dt;
    if (this.spreadTimer < this.spreadInterval * this.spreadMultiplier) return null;
    this.spreadTimer = 0;

    const corrupted = this.segments.filter((s) => s.corrupted);
    for (let attempt = 0; attempt < 8 && corrupted.length; attempt++) {
      const source = corrupted[Math.floor(Math.random() * corrupted.length)];
      const neighbours = [-3, -2, -1, 1, 2, 3]
        .map((offset) => this.segments[source.index + offset])
        .filter((s) => s && !s.terminal && !s.corrupted && !s.protected);
      if (neighbours.length) {
        const target = neighbours[Math.floor(Math.random() * neighbours.length)];
        this.infect(target);
        return target;
      }
    }
    return null;
  }

  // Patching a terminal cleans and shields everything near it.
  patch(terminal, radius = PROTECT_RADIUS) {
    terminal.patched = true;
    terminal.segment.el.classList.add(PATCHED_CLASS);
    const centre = terminal.segment.y;
    this.segments.forEach((s) => {
      if (Math.abs(s.y - centre) > radius) return;
      s.protected = true;
      if (s.corrupted) this.cleanse(s);
    });
  }

  // Cleanse a random share of all corrupted ledges.
  rollback(share) {
    const corrupted = this.segments.filter((s) => s.corrupted).sort(() => Math.random() - 0.5);
    corrupted.slice(0, Math.ceil(corrupted.length * share)).forEach((s) => this.cleanse(s));
  }

  reset() {
    this.segments.forEach((s) => s.el.classList.remove(CORRUPTED_CLASS, PATCHED_CLASS));
  }
}
