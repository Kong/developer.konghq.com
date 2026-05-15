import { morph } from "./morph";
import { Game } from "./game";

const SHAKE_MS = 600;
const FLASH_DELAY = 350;
const BOTTOM_THRESHOLD = 4;

const FLASH_GORILLA = `          ██████████
        ██▒▒▒▒▒▒▒▒▒▒██
      ██▒▒▒▒  ▒▒▒▒▒▒▒▒▓▓
      ██▒▒  ░░▒▒▒▒▒▒▒▒██
    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    ██▒▒  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    ██▒▒  ▒▒▒▒▒▒▒▒▒▒▓▓▒▒██
    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
    ░░▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒██
      ██▒▒▒▒▒▒▒▒▒▒▒▒████
        ██▒▒▓▓▒▒▒▒▓▓██
        ██▓▓▒▒▓▓▓▓████
          ██▓▓▓▓████
          ██████████`;

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

document.addEventListener("DOMContentLoaded", () => {
  if (isMobile()) return;
  if (scroller().scrollHeight <= window.innerHeight + BOTTOM_THRESHOLD) return;

  const heading = Array.from(document.querySelectorAll("footer h5")).find(
    (h) => h.textContent.trim() === "Powering the API world",
  );
  if (!heading || !heading.parentElement) return;
  const container = heading.parentElement;

  const banner = document.createElement("div");
  banner.className = "bullet-hell-engage";
  banner.setAttribute("role", "button");
  banner.setAttribute("tabindex", "0");
  banner.setAttribute("aria-label", "Player 1 Start — launch hidden game");
  banner.innerHTML = `
    <div class="bullet-hell-engage-panel">
      <pre class="bullet-hell-engage-gorilla">${FLASH_GORILLA}</pre>
      <div class="bullet-hell-engage-text">
        <div class="bullet-hell-engage-title">PLAYER 1 START</div>
        <div class="bullet-hell-engage-subtitle">CLICK TO ENGAGE</div>
      </div>
    </div>
  `;
  container.appendChild(banner);

  let state = "idle";
  let activeGame = null;
  let prevY = scroller().scrollTop;

  window.addEventListener(
    "scroll",
    () => {
      if (state !== "idle") return;
      const y = scroller().scrollTop;
      const goingDown = y > prevY;
      prevY = y;
      if (!goingDown || !atBottom()) return;

      state = "revealing";
      document.body.classList.add("bullet-hell-shake");
      setTimeout(
        () => document.body.classList.remove("bullet-hell-shake"),
        SHAKE_MS,
      );
      setTimeout(reveal, FLASH_DELAY);
    },
    { passive: true },
  );

  function reveal() {
    banner.classList.add("bullet-hell-engage--ready");
    state = "ready";
  }

  banner.addEventListener("click", () => {
    if (state === "ready") start();
  });
  banner.addEventListener("keydown", (e) => {
    if ((e.key === "Enter" || e.key === " ") && state === "ready") {
      e.preventDefault();
      start();
    }
  });

  async function start() {
    if (activeGame) return;
    state = "running";
    banner.style.visibility = "hidden";
    document.documentElement.style.overflow = "hidden";

    const game = new Game([], () => {
      document.documentElement.style.overflow = "";
      banner.style.visibility = "";
      activeGame = null;
      state = "ready";
    });
    game.mountChrome();
    activeGame = game;

    const { sprites, restore } = await morph();
    game.onExit = ((orig) => () => {
      restore();
      orig();
    })(game.onExit);

    game.setSprites(sprites);
    game.start();
  }
});
