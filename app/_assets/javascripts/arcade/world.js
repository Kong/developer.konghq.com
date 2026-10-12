// The level is generated from the current docs page. Corruption spreads
// through the page's blocks (paragraphs, rows, headings); a sparse set of
// chunky one-way ledges is anchored to those blocks and collapses when its
// block is corrupted. Ledges sit in evenly spaced lanes and zigzag down the
// page. Code blocks host terminals and the footer is the floor. All
// coordinates are document coordinates.

const BLOCK_SELECTOR =
  "h1, h2, h3, h4, h5, h6, p, li, tr, pre, img, .mermaid, blockquote, figure, hr, .code-block, table";
const SAME_TOP = 8;
const MIN_GAP = 110;
const MAX_GAP = 160;
const LANE_WIDTH = 220;
const LANE_COUNT = [3, 5];
const LANE_PADDING = 40;
const BRICK = 28;
const MAX_TERMINALS = 6;
const MIN_TERMINALS = 3;
const TERMINAL_SPACING = 700;
const SEED_BLOCKS = 4;
// How far corruption can tunnel past shielded blocks and terminals.
const SPREAD_REACH = 6;
const CORRUPTED_CLASS = "arcade-corrupted";
// How close an agent has to pass to a ledge to corrupt it.
const INFECT_DISTANCE = 14;

export const LEDGE_HEIGHT = 20;
export const LOSE_RATIO = 0.6;
export const SHIELD = { radius: 280, seconds: 20 };
export const FIREWALL = { radius: 450, seconds: 12 };
// Generous estimates of what a double jump can clear. Used to decide when a
// terminal has been cut off for good.
export const UP_REACH = 250;
export const SIDE_REACH = 260;
const FALL_WINDOW = 800;

export const PLUGINS = [
  { name: "Rate Limiting", effect: "throttle", summary: "Slows corruption", text: "Corruption throttled" },
  { name: "AI Prompt Guard", effect: "firewall", summary: "Wide shield, 12s", text: "Firewall up: wide shield for 12s" },
  { name: "OpenID Connect", effect: "deauth", summary: "Destroys agents", text: "Rogue agents de-authenticated" },
  {
    name: "AI Semantic Prompt Guard",
    effect: "rollback",
    summary: "Reverses corruption",
    text: "Semantic rollback: a third of the corruption reversed",
  },
  { name: "Bot Detection", effect: "slowOrbs", summary: "Slows agents", text: "Bots detected: agents slowed" },
  {
    name: "AI Rate Limiting Advanced",
    effect: "budget",
    summary: "Slows corruption + agents",
    text: "Token budget enforced",
  },
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
    this.blocks = [];
    this.segments = [];
    this.terminals = [];
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
    // code-block/pre) would be a duplicate, so keep the child only.
    const elements = candidates.filter(
      (el) =>
        !candidates.some(
          (other) => other !== el && el.contains(other) && Math.abs(rects.get(other).top - rects.get(el).top) < SAME_TOP
        )
    );

    return elements
      .map((el) => {
        const rect = rects.get(el);
        return {
          el,
          x: rect.left + window.scrollX,
          y: rect.top + window.scrollY,
          w: rect.width,
          h: rect.height,
          terminal: false,
          corrupted: false,
          shield: 0,
        };
      })
      .sort((a, b) => a.y - b.y || a.x - b.x)
      .map((block, index) => ({ ...block, index }));
  }

  collect() {
    this.measureColumn();
    this.makeFloor();
    this.blocks = this.collectBlocks();
    if (this.blocks.length < 5) return;

    const terminalBlocks = this.pickTerminalBlocks(this.blocks);
    terminalBlocks.forEach((block) => (block.terminal = true));
    this.build(this.blocks, terminalBlocks);

    this.segments.sort((a, b) => a.y - b.y || a.x - b.x);
    this.segments.forEach((segment, index) => (segment.index = index));

    this.terminals = this.segments
      .filter((segment) => segment.terminal)
      .map((segment, i) => ({ segment, plugin: PLUGINS[i], patched: false, progress: 0 }));

    // Give the player enough time to physically reach every terminal on long
    // pages: roughly the run time from top to bottom, plus slack.
    const pageHeight = document.documentElement.scrollHeight;
    const loseSeconds = Math.max(30, pageHeight / 330 + 12);
    this.spreadInterval = loseSeconds / Math.max(1, this.corruptible().length * LOSE_RATIO);
  }

  // Spread terminals evenly down the page: one target height per terminal,
  // filled by the nearest code block, else the nearest heading.
  pickTerminalBlocks(blocks) {
    const eligible = blocks.filter((b) => b.index > 1);
    const code = eligible.filter((b) => b.el.matches("pre:not(.mermaid)"));
    const headings = eligible.filter((b) => b.el.matches("h2, h3"));
    if (!eligible.length) return new Set();

    const top = eligible[0].y;
    const span = eligible[eligible.length - 1].y - top;
    const count = Math.min(clamp(Math.round(span / TERMINAL_SPACING), MIN_TERMINALS, MAX_TERMINALS), eligible.length);
    const spacing = span / count;
    const chosen = new Set();
    const nearest = (pool, y) =>
      pool
        .filter((b) => !chosen.has(b) && Math.abs(b.y - y) < spacing / 2)
        .sort((a, b) => Math.abs(a.y - y) - Math.abs(b.y - y))[0];

    for (let i = 0; i < count; i++) {
      const target = top + spacing * (i + 0.5);
      const block = nearest(code, target) || nearest(headings, target) || nearest(eligible, target);
      if (block) chosen.add(block);
    }
    return chosen;
  }

  // Ledges step one lane at a time, sweeping left and right across the
  // column. Terminals always sit in the rightmost lane.
  build(blocks, terminalBlocks) {
    const width = this.right - this.left;
    this.laneCount = clamp(Math.floor(width / LANE_WIDTH), ...LANE_COUNT);
    this.laneWidth = width / this.laneCount;
    this.ledgeWidth = Math.max(BRICK * 3, Math.floor((this.laneWidth - LANE_PADDING) / BRICK) * BRICK);
    this.direction = 1;

    const terminalTops = [...terminalBlocks].map((b) => b.y);
    let prev = this.addSegment(blocks[0], 0, 0, "ledge");

    for (const block of blocks.slice(1)) {
      const isTerminal = terminalBlocks.has(block);
      if (!isTerminal) {
        if (block.y - prev.y < MIN_GAP) continue;
        // Leave headroom above terminals.
        if (terminalTops.some((top) => top > block.y && top - block.y < MIN_GAP)) continue;
      }

      prev = this.fillDown(prev, block, this.anchorTop(block));

      if (isTerminal) {
        const lane = this.laneCount - 1;
        prev = this.walkToLane(prev, block, lane);
        prev = this.addSegment(block, lane, 0, "terminal");
        this.direction = -1;
      } else {
        prev = this.addSegment(block, this.nextLane(prev.lane), 0, "ledge");
      }
    }

    // Keep stepping down to the floor so the player can always climb back up.
    this.fillDown(prev, blocks[blocks.length - 1], this.floor.y);
  }

  nextLane(lane) {
    if (lane + this.direction < 0 || lane + this.direction >= this.laneCount) this.direction = -this.direction;
    return lane + this.direction;
  }

  // Floating ledges between `prev` and `targetY`, so no step is taller than a
  // jump. Fillers are anchored to `block` and fall with it.
  fillDown(prev, block, targetY) {
    const baseY = prev.y;
    const gap = targetY - baseY;
    const steps = Math.ceil(gap / MAX_GAP);
    for (let step = 1; step < steps; step++) {
      const y = baseY + (gap * step) / steps;
      prev = this.addSegment(block, this.nextLane(prev.lane), y - this.anchorTop(block), "filler");
    }
    return prev;
  }

  // Step lane by lane towards `lane`, spreading the steps between `prev` and
  // the block's row.
  walkToLane(prev, block, lane) {
    const steps = Math.abs(lane - prev.lane) - 1;
    if (steps <= 0) return prev;
    const baseY = prev.y;
    const gap = this.anchorTop(block) - baseY;
    const towards = Math.sign(lane - prev.lane);
    for (let step = 1; step <= steps; step++) {
      const y = baseY + (gap * step) / (steps + 1);
      prev = this.addSegment(block, prev.lane + towards, y - this.anchorTop(block), "filler");
    }
    return prev;
  }

  anchorTop(block) {
    return block.y - LEDGE_HEIGHT;
  }

  laneX(lane) {
    return this.left + lane * this.laneWidth + (this.laneWidth - this.ledgeWidth) / 2;
  }

  // A ledge sits on top of its anchor block, so its collision line is
  // LEDGE_HEIGHT above the block's top edge (plus any offset for fillers).
  addSegment(block, lane, dy, kind) {
    const segment = {
      block,
      kind,
      lane,
      dy,
      x: this.laneX(lane),
      y: this.anchorTop(block) + dy,
      w: this.ledgeWidth,
      terminal: kind === "terminal",
      get corrupted() {
        return !this.terminal && this.block.corrupted;
      },
      get shield() {
        return this.block.shield;
      },
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
    this.laneWidth = (this.right - this.left) / this.laneCount;
    this.blocks.forEach((block) => {
      const rect = block.el.getBoundingClientRect();
      block.x = rect.left + window.scrollX;
      block.y = rect.top + window.scrollY;
      block.w = rect.width;
      block.h = rect.height;
    });
    this.segments.forEach((segment) => {
      segment.y = this.anchorTop(segment.block) + segment.dy;
      segment.x = this.laneX(segment.lane);
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
    return this.segments.filter((s) => !s.corrupted).concat(this.floor);
  }

  corruptible() {
    return this.blocks.filter((b) => !b.terminal);
  }

  corruptionRatio() {
    const pool = this.corruptible();
    if (!pool.length) return 0;
    return pool.filter((b) => b.corrupted).length / pool.length;
  }

  lost() {
    return this.corruptionRatio() >= LOSE_RATIO;
  }

  allPatched() {
    return this.terminals.length > 0 && this.terminals.every((t) => t.patched);
  }

  // Walks every jump the player could still make from `start` and returns the
  // first unpatched terminal that can no longer be reached, if any. Only
  // nearby ledges are considered: a long fall lands on the first ledge
  // underneath anyway, and the floor is always reachable.
  unreachableTerminal(start) {
    const nodes = this.segments.filter((s) => !s.corrupted);
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
    this.blocks.forEach((block) => {
      if (!block.corrupted) return;
      const distance = Math.hypot(clamp(x, block.x, block.x + block.w) - x, block.y - y);
      if (distance < bestDistance) {
        best = block;
        bestDistance = distance;
      }
    });
    return best;
  }

  // A plain ledge a comfortable distance below `y`, for the exit door.
  exitLedge(y) {
    const below = this.segments.filter((s) => !s.terminal && s.y > y + 200);
    return below.find((s) => s.y > y + 350) || below[below.length - 1] || null;
  }

  // --- corruption ----------------------------------------------------------

  tick(dt) {
    this.blocks.forEach((block) => {
      if (block.shield > 0) block.shield = Math.max(0, block.shield - dt);
    });
  }

  seed() {
    this.corruptible()
      .filter((b) => b.index > 1)
      .slice(0, SEED_BLOCKS)
      .forEach((b) => this.infect(b));
  }

  infect(block) {
    block.corrupted = true;
    block.el.classList.add(CORRUPTED_CLASS);
    this.lastInfected = block;
  }

  cleanse(block) {
    block.corrupted = false;
    block.el.classList.remove(CORRUPTED_CLASS);
  }

  cleanseAll() {
    this.blocks.forEach((b) => b.corrupted && this.cleanse(b));
  }

  // The first block corruption can take in one direction from `source`. It
  // tunnels underneath shielded blocks and terminals without infecting them.
  frontier(source, direction) {
    for (let step = 1; step <= SPREAD_REACH; step++) {
      const block = this.blocks[source.index + direction * step];
      if (!block) return null;
      if (block.terminal || block.shield > 0 || block.corrupted) continue;
      return block;
    }
    return null;
  }

  // Corruption spreads along the page: each step a random corrupted block
  // infects the nearest clean block above or below it. Returns the newly
  // infected block, if any.
  spread(dt) {
    this.spreadTimer += dt;
    if (this.spreadTimer < this.spreadInterval * this.spreadMultiplier) return null;
    this.spreadTimer = 0;

    const corrupted = this.blocks.filter((b) => b.corrupted);
    for (let attempt = 0; attempt < 12 && corrupted.length; attempt++) {
      const source = corrupted[Math.floor(Math.random() * corrupted.length)];
      const targets = [this.frontier(source, 1), this.frontier(source, -1)].filter(Boolean);
      if (targets.length) {
        const target = targets[Math.floor(Math.random() * targets.length)];
        this.infect(target);
        return target;
      }
    }
    return null;
  }

  // Patching a terminal cleans the area around it and shields it for a while.
  patch(terminal, { radius, seconds } = SHIELD) {
    terminal.patched = true;
    const centre = terminal.segment.y;
    this.blocks.forEach((block) => {
      if (Math.abs(block.y - centre) > radius) return;
      block.shield = Math.max(block.shield, seconds);
      if (block.corrupted) this.cleanse(block);
    });
  }

  // An agent passing through a clean, unshielded ledge corrupts its block.
  // Returns the infected block, if any.
  infectAt(x, y) {
    const start = lowerBound(this.segments, y - INFECT_DISTANCE);
    for (let i = start; i < this.segments.length && this.segments[i].y <= y + INFECT_DISTANCE; i++) {
      const segment = this.segments[i];
      const { block } = segment;
      if (segment.terminal || block.corrupted || block.shield > 0) continue;
      if (x < segment.x || x > segment.x + segment.w) continue;
      this.infect(block);
      return block;
    }
    return null;
  }

  // Cleanse a random share of all corrupted blocks.
  rollback(share) {
    const corrupted = this.blocks.filter((b) => b.corrupted).sort(() => Math.random() - 0.5);
    corrupted.slice(0, Math.ceil(corrupted.length * share)).forEach((b) => this.cleanse(b));
  }

  reset() {
    this.blocks.forEach((b) => b.el.classList.remove(CORRUPTED_CLASS));
  }
}
