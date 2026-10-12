# Docs arcade (hidden easter egg)

A hidden pixel platformer on developer.konghq.com. Typing `0451` on any docs page turns that page into a level: a rogue AI corrupts the docs, and the player (the Kong logo mark, a gorilla) runs across the page enabling Kong plugins at terminals to govern it, then escapes through an exit door.

This file is the handoff for iterating on the game. It records the owner's intent and decisions; the code is the source of truth for current values, so constants are named here, not copied.

## Status

- Work-in-progress on branch `feat/arcade-easter-egg`, local only. Not pushed, no PR.
- Target: ship live to everyone on merge to `main`. No feature flag and no brand/legal sign-off needed (owner decision). Rolling back means reverting the merge.
- The owner playtests in their own browser and reports how it feels; tuning is driven by that feedback.

## Intent

- **Delight first, cheap for everyone else.** Regular page views load only the trigger and the header trophy (`../arcade.js`, `trophy.js`). The game is a lazy chunk loaded on the code.
- **The page is the level.** Nothing is hand-authored per page; every docs page must produce a playable level, including hub pages without `<main>`.
- **The story is Kong's.** You are the gateway: each terminal is a real Kong plugin whose effect fits its purpose (Bot Detection slows bots, OpenID Connect de-authenticates agents). The mission text says so in the prompt, the opening toast, and the HUD.
- **Leave no trace.** Esc twice restores the page exactly: no stray classes, scroll position restored, canvas removed.
- **Discoverable, not obvious.** The only clue is a tooltip on the header logo: "This game is very ## **immersive** ##..." (`0451` is the classic immersive-sim door code).

## Working with the owner

- They want a recommendation with each choice, then they decide. Small, targeted tuning steps; "nothing drastic, don't make it too easy again".
- When they give a number, use it exactly. If a coupling would cancel the change, say so and fix the coupling (see `PACE_RATIO` in [Gotchas](#gotchas)).
- Verify in the browser before reporting, and report with evidence (screenshots, measured values).
- Commit to `feat/arcade-easter-egg` only. Ask before creating branches, squashing, or pushing.

## Settled decisions

These were chosen by the owner, often after trying the alternative. Change them only when asked.

### Flow

- `0451` anywhere except form fields → Matrix rain (any key skips) → WarGames-style "SHALL WE PLAY A GAME? [Y/N]" with the mission → play.
- Controls: arrows/WASD move, Space jump with one double jump, ↓ drops through a ledge (hold to keep falling), hold E at a terminal to enable its plugin, mouse wheel looks around, M mutes, Esc twice exits. A keybar at the bottom lists them.
- Win: enable every terminal → corruption clears, agents vanish, a flashing EXIT door opens a little further down the page → reach it.
- Lose: corruption reaches `LOSE_RATIO`, all lives gone, or a terminal stays cut off for `CUTOFF_GRACE` seconds (a red countdown warns first and clears if a path reopens).
- Winning stores the best time in `localStorage` key `kong-docs-arcade` and shows a pixel star beside the header logo (tooltip with time, links to Kong careers). The win screen shows time and best time, and C opens careers. Clear it with `localStorage.removeItem("kong-docs-arcade")`.

### Accessibility

- Starting the game announces "Docs arcade started. Press Escape twice to exit." through a visually hidden `aria-live` region.
- Before play starts (rain and the Y/N prompt) a single Esc exits; Esc twice only applies once a run is in progress.
- With `prefers-reduced-motion`, flashing states (corrupted ledges, invulnerability blink, exit door) are drawn steady instead of flickering.
- Touch and mobile are out of scope: the trigger needs a keyboard, so touch users never reach the game.

### Analytics

Minimal Segment events through `window.analytics?.track(...)` with the site's consent context, so nothing is sent when Segment is absent or blocked. No user-identifying properties.

| Event | When | Properties |
|---|---|---|
| `Arcade Started` | Code typed | |
| `Arcade Played` | Y pressed at the prompt | |
| `Arcade Ended` | Run ends or player quits | `outcome` (`won`/`lost`/`quit`), `reason`, `seconds` |
| `Arcade Careers Clicked` | C on the win screen or the header star | `source` |

### Level

- Ledges are chunky brick platforms in evenly spaced lanes, zigzagging one lane per step. Sparse on purpose: the owner rejected "a ledge on every block" (too many, too thin) and random placement (messy, overlapping).
- Ledges are one-way: solid from above, jump up through them.
- Terminals are spaced evenly by page height (3 to 5 by page length), preferring code blocks, then headings. They sit in the rightmost lane, labelled with the plugin name and its effect.
- The camera follows the player; the wheel pans and the view stays put until a move, jump, drop, or use key.
- A minimap down the right edge shows corruption, terminals, the view, the player, and the exit door.

### Corruption and agents

- Corruption spreads through page blocks (visible red glitching on the docs) and collapses any ledge anchored to a corrupted block. It tunnels past shields and terminals rather than stopping at them (it used to stall; the owner wants it to keep moving).
- Agents are red orbs that drift after the player, expire after a while, and corrupt ledges they pass through. They spawn from corrupted blocks at least `ORB_SPAWN_MIN` away so the player sees them coming.
- Three lives, knockback and brief invulnerability on a hit.

### Plugins

Five plugins (Rate Limiting was removed), shuffled per page with the page's seed so short pages get a mix. Each plugin is one entry in `PLUGINS` (`plugins.js`): its text, an optional wider `shield`, a timed effect (`seconds` plus `modifiers` that multiply game values while it runs, read through `Game.modifier()`), or an instant `enable(game)`. A new timed plugin needs no change to `game.js`.

Every terminal also clears corruption near it and shields that area briefly (`SHIELD`). The owner deliberately removed any permanent "every terminal makes agents weaker" effect: the game was too easy with it.

| Plugin | Effect (owner-specified) |
|---|---|
| AI Prompt Guard | A wider shield (its `shield`), same short duration |
| OpenID Connect | Destroys the half of the agents nearest the player, pauses spawning briefly |
| AI Semantic Prompt Guard | Reverses a share of all corruption (`ROLLBACK_SHARE`) |
| Bot Detection | Agents move at half speed for `EFFECT_SECONDS` |
| AI Rate Limiting Advanced | Corruption and agent spawning slowed for `EFFECT_SECONDS` |

The HUD lists each plugin with its effect and a live countdown while a timed effect runs.

### Look and sound

- Player: the real Kong mark (paths copied from the header SVG), pixelated at runtime, with a walk cycle built by nudging its four shapes, squash-and-stretch on jumps, and a waddle. The owner liked the squash in particular.
- Terminals: monitors with the Kong mark on screen. Sprites are strings in `sprites.js`, outlined so they read on light and dark themes.
- Sound: every effect is synthesised with Web Audio (`audio.js`), no files. The owner liked it as is.

## Code map

| File | Owns |
|---|---|
| `../arcade.js` | Trigger: listens for `0451`, lazy-loads `game.js`, calls `initTrophy()` |
| `trophy.js` | Logo hint tooltip, completion star, best-time storage, `CAREERS_URL` |
| `game.js` | State machine (`rain` → `prompt` → `playing` → `won`/`lost`), input, physics, camera, agents, plugin effects, cut-off countdown, teardown |
| `world.js` | Level generation from the DOM, corruption, shields, reachability check |
| `plugins.js` | `PLUGINS` registry: text, shield, timed modifiers, instant effects |
| `constants.js` | Values shared across modules: palette, `BRICK` |
| `render.js` | Canvas drawing: world, HUD, minimap, keybar, toasts, banners, rain, prompt |
| `sprites.js` | Pixel art strings and the Kong mark rasteriser |
| `audio.js` | Synthesised sound effects |
| `analytics.js` | `track()`: Segment events, no-op without Segment; logged to the console in dev |

Concepts that carry the design:

- **Blocks** are page elements (`world.blocks`); corruption lives on them. **Segments** are ledges (`world.segments`) anchored to a block; a segment's `corrupted` and `shield` are getters reading its block, so collision, rendering, and reachability follow the block automatically.
- All positions are document coordinates. The canvas is a fixed, pointer-events-none overlay drawn at `(x - scrollX, y - scrollY)`.
- Physics runs at a fixed 120 Hz step, decoupled from the frame rate.
- Level layout is seeded from `location.pathname`, so a page always builds the same level.
- The tuning knobs are the named constants at the top of `game.js`, `world.js` and `plugins.js`.

## Gotchas

- **`PACE_RATIO` vs `LOSE_RATIO`.** Spread speed is tuned so a page reaches `PACE_RATIO` in a target time. `LOSE_RATIO` is higher, and the gap is the player's margin. Raising `LOSE_RATIO` alone used to make corruption spread faster and cancel the change.
- **Small pages.** Percent-based rules break on pages with few blocks. The corruption meter divides by at least `MIN_METER_BLOCKS`, seeds scale with page size, and orb infection cooldown grows on small pages.
- **Pages without `<main>`.** The root falls back to `<body>`; anything inside `CHROME` (header, nav, footer) is excluded, and the play column is sized to the blocks. Without that, the player spawned inside the sticky header.
- **The site tooltip binds once.** The site's `[data-tooltip]` script only binds elements present at load and skips touch-capable devices (including touchscreen laptops with a mouse). `trophy.js` reuses the shared `#tooltip` element with its own handlers instead.
- **External link icon.** Site CSS adds an icon to off-site links; the star uses the existing `no-icon` class.
- **Vite reloads the page** when any arcade file changes. Re-run the game after every edit before testing.

## Testing

The dev server runs on `http://localhost:8888` (see the repo `CLAUDE.md`). Use the `agent-browser` skill with a named session at 1440×900.

In dev, the running game is `window.__arcade`, so state can be read and driven directly (`__arcade.world`, `__arcade.player`, `__arcade.enable(terminal)`, `__arcade.spreadDelay = 1e9` to freeze corruption, `__arcade.player.invulnerable = 1e9`). Wrap `agent-browser eval` code in an IIFE, because eval shares a global scope across calls. `agent-browser keydown` sends an empty `event.code`; the game falls back to `event.key` for that reason.

Boot helper (open a page, type the code, skip the intro, start):

```bash
#!/usr/bin/env bash
# usage: arcade-boot.sh <path>
export AGENT_BROWSER_SESSION=${AGENT_BROWSER_SESSION:-arcade}
agent-browser open "http://localhost:8888$1" >/dev/null
agent-browser wait 1500 >/dev/null
for k in 0 4 5 1; do agent-browser press $k >/dev/null; done
for i in $(seq 1 20); do
  s=$(agent-browser eval '(()=>window.__arcade?.state||"none")()' 2>/dev/null)
  [[ "$s" == '"rain"' || "$s" == '"prompt"' ]] && break
  sleep 0.3
done
agent-browser press x >/dev/null; sleep 0.2; agent-browser press x >/dev/null; sleep 0.2
agent-browser press y >/dev/null
agent-browser eval '(()=>window.__arcade?.state)()'
```

Checks worth re-running after level or pacing changes, on a spread of pages (`/gateway/entities/service/` short, `/plugins/rate-limiting/` medium, `/gateway/version-support-policy/` tables, `/gateway/configuration/` 105k px, `/ai-gateway/policies/?category=serverless` hub without `<main>`):

- Every terminal reachable at the start: `__arcade.world.unreachableTerminal(__arcade.world.floor)` and `...(__arcade.world.segments[0])` both return `undefined`.
- Player spawns on the page (`__arcade.player.y > 0`).
- 60 fps on the long page.
- Idle survival (start, stand still, sample `runTime`, `state`, `loseReason` every 5s) as a rough difficulty signal. It only measures a passive player; the owner's playtest is the real check.

## Open questions and ideas

- AI Prompt Guard is only marginally stronger than the default shield; the owner may want it to stand out more.
- Corruption starts near the top of the page, close to the first terminal on short pages, so an idle player can get that terminal cut off quickly.
- Not yet tried: music, a pause key, hub and landing page layouts beyond the policies hub.
- Production Vite build verified: the game is its own lazy chunk (about 15 kB gzipped), the main bundle only gains the trigger, trophy and analytics helper, and `window.__arcade` is stripped. A full `make build` (Jekyll) hasn't been run locally because it writes to the `dist/` the dev server serves; the Netlify preview build covers it.
- Planned after the production pass: split `game.js` (player and agents into their own modules).
- No JS unit test runner for now (owner decision: no new dependency). Testing is the browser checklist in [Testing](#testing) plus the owner's playtests.
