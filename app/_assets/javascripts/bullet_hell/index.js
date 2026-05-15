import { morph } from "./morph";
import { Game } from "./game";

const SHAKE_MS = 600;
const SCROLL_AWAY_THRESHOLD = 200;
const BOTTOM_THRESHOLD = 4;

function isMobile() {
  return (
    window.matchMedia("(pointer: coarse)").matches ||
    window.innerWidth < 768
  );
}

function scroller() {
  return document.scrollingElement || document.documentElement;
}

function atBottom() {
  const se = scroller();
  return se.scrollTop + window.innerHeight >= se.scrollHeight - BOTTOM_THRESHOLD;
}

function scrolledAway() {
  const se = scroller();
  return se.scrollTop < se.scrollHeight - window.innerHeight - SCROLL_AWAY_THRESHOLD;
}

document.addEventListener("DOMContentLoaded", () => {
  if (isMobile()) return;
  if (scroller().scrollHeight <= window.innerHeight + BOTTOM_THRESHOLD) return;

  let state = "idle";
  let activeGame = null;
  let prevY = scroller().scrollTop;

  window.addEventListener("scroll", () => {
    if (state === "running") return;

    const y = scroller().scrollTop;
    const goingDown = y > prevY;
    prevY = y;

    if (state === "idle" && goingDown && atBottom()) {
      state = "shaken";
      document.body.classList.add("bullet-hell-shake");
      setTimeout(() => document.body.classList.remove("bullet-hell-shake"), SHAKE_MS);
      return;
    }

    if (state === "shaken" && scrolledAway()) {
      state = "armed";
      return;
    }

    if (state === "armed" && goingDown && atBottom()) {
      state = "running";
      start();
    }
  }, { passive: true });

  async function start() {
    document.documentElement.style.overflow = "hidden";

    const game = new Game([], () => {
      document.documentElement.style.overflow = "";
      activeGame = null;
      state = "idle";
    });
    game.mountChrome();
    activeGame = game;

    const { sprites, restore } = await morph();
    game.onExit = (orig => () => {
      restore();
      orig();
    })(game.onExit);

    game.setSprites(sprites);
    game.start();
  }
});
