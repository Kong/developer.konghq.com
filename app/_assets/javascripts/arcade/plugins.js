// The Kong plugins enabled at terminals. Every terminal clears corruption
// near it and shields that area (`shield`, default SHIELD in world.js). A
// plugin can then:
// - run a timed effect for `seconds`, during which its `modifiers` multiply
//   the matching game values (see Game.modifier());
// - do something instantly in `enable(game)`.
// `remaining(game)` overrides the countdown shown in the HUD.

const EFFECT_SECONDS = 10;
const DEAUTH_PAUSE = 5;
const ROLLBACK_SHARE = 0.2;

export const PLUGINS = [
  {
    name: "AI Prompt Guard",
    summary: "Wider shield",
    text: "Firewall up: wider area shielded",
    shield: { radius: 200, seconds: 5 },
  },
  {
    name: "OpenID Connect",
    summary: "Destroys half the agents",
    text: "Nearest agents de-authenticated",
    enable: (game) => game.agents.deauthenticate(game.player, DEAUTH_PAUSE),
    remaining: (game) => Math.max(0, game.agents.pause),
  },
  {
    name: "AI Semantic Prompt Guard",
    summary: "Reverses some corruption",
    text: `Semantic rollback: ${ROLLBACK_SHARE * 100}% of the corruption reversed`,
    enable: (game) => game.world.rollback(ROLLBACK_SHARE),
  },
  {
    name: "Bot Detection",
    summary: "Slows agents",
    text: `Bots detected: agents slowed for ${EFFECT_SECONDS}s`,
    seconds: EFFECT_SECONDS,
    modifiers: { orbSpeed: 0.5 },
  },
  {
    name: "AI Rate Limiting Advanced",
    summary: "Slows corruption + agents",
    text: `Token budget enforced for ${EFFECT_SECONDS}s`,
    seconds: EFFECT_SECONDS,
    // Multiplies the spread and spawn intervals, so higher is slower.
    modifiers: { spreadInterval: 1.6, spawnInterval: 1.5 },
  },
];
