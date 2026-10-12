// The level is generated from the current docs page. Corruption spreads
// through the page's blocks (paragraphs, rows, headings); a sparse set of
// chunky one-way ledges is anchored to those blocks and collapses when its
// block is corrupted. Ledges sit in evenly spaced lanes and zigzag down the
// page. Code blocks host terminals and the footer is the floor. All
// coordinates are document coordinates.

import { BRICK, clamp } from "./constants";
import { PLUGINS } from "./plugins";

const BLOCK_SELECTOR =
  "h1, h2, h3, h4, h5, h6, p, li, tr, pre, img, .mermaid, blockquote, figure, hr, .code-block, table";
const SAME_TOP = 8;
const MIN_GAP = 110;
const MAX_GAP = 160;
const LANE_WIDTH = 220;
const LANE_COUNT = [3, 5];
const LANE_PADDING = 40;
const MAX_TERMINALS = 5;
const MIN_TERMINALS = 3;
const TERMINAL_SPACING = 700;
// Corruption starts in a share of the page's blocks, so small pages don't
// begin most of the way to losing.
const SEED_SHARE = 0.08;
const SEED_BLOCKS = [1, 4];
// Site chrome is never part of the level, even on pages without <main>.
const CHROME = "header, nav, footer, [role='navigation'], [role='banner'], [role='contentinfo']";
// Keep the right lane and its terminal labels clear of the minimap.
const RIGHT_MARGIN = 100;
// The corruption meter counts at least this many blocks, so on tiny pages a
// single block isn't a big chunk of the way to losing.
const MIN_METER_BLOCKS = 16;
// How far corruption can tunnel past shielded blocks and terminals.
const SPREAD_REACH = 6;
const CORRUPTED_CLASS = "arcade-corrupted";
// How close an agent has to pass to a ledge to corrupt it.
const INFECT_DISTANCE = 14;

export const LEDGE_HEIGHT = 20;
export const LOSE_RATIO = 0.7;
// Spread speed is tuned so a page reaches this share in the target time; the
// gap up to LOSE_RATIO is the player's extra margin.
const PACE_RATIO = 0.6;
export const SHIELD = { radius: 150, seconds: 5 };
// Generous estimates of what a double jump can clear. Used to decide when a
// terminal has been cut off for good.
const UP_REACH = 250;
const SIDE_REACH = 340;
const FALL_WINDOW = 800;
// Every page gets at least this long to reach PACE_RATIO, so short pages
// still have a chase but don't spread at a crawl.
const MIN_PACE_SECONDS = 20;

function isVisible(el) {
  const rect = el.getBoundingClientRect();
  if (rect.width < 40 || rect.height < 2) return false;
  return el.checkVisibility ? el.checkVisibility({ visibilityProperty: true }) : true;
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

// Fisher-Yates, in place.
function shuffle(items, random = Math.random) {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
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
    // Blocks corruption can take: everything but terminals. Fixed once built.
    this.corruptibleBlocks = [];
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
    const candidates = [...this.root.querySelectorAll(BLOCK_SELECTOR)].filter(
      (el) => !el.closest(CHROME) && isVisible(el)
    );
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
    this.makeFloor();
    this.blocks = this.collectBlocks();
    this.measureColumn();
    if (this.blocks.length < 5) return;

    const terminalBlocks = this.pickTerminalBlocks(this.blocks);
    terminalBlocks.forEach((block) => (block.terminal = true));
    this.corruptibleBlocks = this.blocks.filter((b) => !b.terminal);
    this.build(this.blocks, terminalBlocks);

    this.segments.sort((a, b) => a.y - b.y || a.x - b.x);
    this.segments.forEach((segment, index) => (segment.index = index));

    // Shuffle the plugins per page so short pages still get a mix.
    const plugins = shuffle([...PLUGINS], this.random);
    this.terminals = this.segments
      .filter((segment) => segment.terminal)
      .map((segment, i) => ({ segment, plugin: plugins[i], patched: false, progress: 0 }));

    // Give the player enough time to physically reach every terminal on long
    // pages: roughly the run time from top to bottom, plus slack.
    const pageHeight = document.documentElement.scrollHeight;
    const paceSeconds = Math.max(MIN_PACE_SECONDS, pageHeight / 330 + 12);
    this.spreadInterval = paceSeconds / Math.max(1, this.corruptible().length * PACE_RATIO);
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
  // column. Terminals alternate between the outer lanes, starting on a side
  // picked by the page's seed, so the route keeps crossing the page.
  build(blocks, terminalBlocks) {
    const width = this.right - this.left;
    this.laneCount = clamp(Math.floor(width / LANE_WIDTH), ...LANE_COUNT);
    this.sizeLanes();
    this.direction = 1;
    let rightSide = this.random() < 0.5;

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
        const lane = rightSide ? this.laneCount - 1 : 0;
        prev = this.walkToLane(prev, block, lane);
        prev = this.addSegment(block, lane, 0, "terminal");
        // Head back across the page, towards the next terminal's side.
        this.direction = rightSide ? -1 : 1;
        rightSide = !rightSide;
      } else {
        prev = this.addSegment(block, this.nextLane(prev.lane), 0, "ledge");
      }
    }

    // Keep stepping down to the floor so the player can always climb back up.
    this.fillDown(prev, blocks[blocks.length - 1], this.floor.y);
  }

  // Lane and ledge widths for the current column. The lane count is fixed at
  // build time because segments store their lane index.
  sizeLanes() {
    this.laneWidth = (this.right - this.left) / this.laneCount;
    this.ledgeWidth = Math.max(BRICK * 3, Math.floor((this.laneWidth - LANE_PADDING) / BRICK) * BRICK);
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

  // The play column is the part of the root the blocks actually cover, which
  // matters on pages that fall back to <body> as the root.
  measureColumn() {
    const rect = this.root.getBoundingClientRect();
    let left = Math.max(0, rect.left) + window.scrollX;
    let right = rect.right + window.scrollX;
    if (this.blocks.length) {
      left = Math.max(left, Math.min(...this.blocks.map((b) => b.x)));
      right = Math.min(right, Math.max(...this.blocks.map((b) => b.x + b.w)));
    }
    this.left = left;
    this.right = Math.min(right, window.scrollX + window.innerWidth - RIGHT_MARGIN);
  }

  layout() {
    this.blocks.forEach((block) => {
      const rect = block.el.getBoundingClientRect();
      block.x = rect.left + window.scrollX;
      block.y = rect.top + window.scrollY;
      block.w = rect.width;
      block.h = rect.height;
    });
    this.measureColumn();
    this.sizeLanes();
    this.segments.forEach((segment) => {
      segment.y = this.anchorTop(segment.block) + segment.dy;
      segment.x = this.laneX(segment.lane);
      segment.w = this.ledgeWidth;
    });
    this.makeFloor();
  }

  makeFloor() {
    const footer = document.querySelector("footer");
    const pageHeight = document.documentElement.scrollHeight;
    const y = footer ? footer.getBoundingClientRect().top + window.scrollY : pageHeight - 4;
    // Updated in place so references to the floor (the player's ground, the
    // exit door's) stay valid across a resize.
    this.floor = Object.assign(this.floor || {}, { x: 0, y, w: document.documentElement.scrollWidth, floor: true });
  }

  // --- queries -------------------------------------------------------------

  // Ledges the player can land on right now.
  solids() {
    return this.segments.filter((s) => !s.corrupted).concat(this.floor);
  }

  corruptible() {
    return this.corruptibleBlocks;
  }

  anyCorrupted() {
    return this.blocks.some((b) => b.corrupted);
  }

  corruptionRatio() {
    const pool = this.corruptible();
    if (!pool.length) return 0;
    return pool.filter((b) => b.corrupted).length / Math.max(pool.length, MIN_METER_BLOCKS);
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

  // Corrupted blocks within maxDistance of a point, with their distances.
  corruptedNear(x, y, maxDistance) {
    return this.blocks
      .filter((block) => block.corrupted)
      .map((block) => ({ block, distance: Math.hypot(clamp(x, block.x, block.x + block.w) - x, block.y - y) }))
      .filter(({ distance }) => distance < maxDistance);
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

  // Starts corruption near the top of the page, skipping shielded blocks.
  seed() {
    const pool = this.corruptible();
    const count = clamp(Math.round(pool.length * SEED_SHARE), ...SEED_BLOCKS);
    pool
      .filter((b) => b.index > 1 && b.shield <= 0)
      .slice(0, count)
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
    const corrupted = shuffle(this.blocks.filter((b) => b.corrupted));
    corrupted.slice(0, Math.ceil(corrupted.length * share)).forEach((b) => this.cleanse(b));
  }

  reset() {
    this.blocks.forEach((b) => b.el.classList.remove(CORRUPTED_CLASS));
  }
}
