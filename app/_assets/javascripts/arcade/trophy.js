// Loaded on every page with the trigger. Adds the hint tooltip to the header
// logo and, once the arcade has been beaten, a pixel star beside it that
// links to Kong careers and shows the best time.

import { track } from "./analytics";

const STORAGE_KEY = "kong-docs-arcade";
const STAR_CLASS = "arcade-star";
const STAR = ["...G...", "...G...", "GGGGGGG", ".GGGGG.", "..GGG..", ".GG.GG.", "GG...GG"];

export const CAREERS_URL = "https://konghq.com/company/careers";

export function formatTime(seconds) {
  const whole = Math.floor(seconds);
  return `${Math.floor(whole / 60)}:${String(whole % 60).padStart(2, "0")}`;
}

function readRecord() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY));
  } catch {
    return null;
  }
}

// The header has separate desktop and mobile logo links.
function headerLogos() {
  return [...document.querySelectorAll("#header-nav a[href='/']")];
}

// The clue on the header logo, with "immersive" in bold.
function renderHint(tooltip) {
  const word = document.createElement("strong");
  word.textContent = "immersive";
  tooltip.replaceChildren("This game is very ## ", word, " ##...");
}

// Reuses the site's shared #tooltip element. The site's own [data-tooltip]
// binding only covers elements present at page load and is switched off on
// touch-capable devices, which includes touchscreen laptops used with a mouse.
function attachTooltip(el, render) {
  const tooltip = document.getElementById("tooltip");
  if (!tooltip) return;

  el.addEventListener("mouseenter", () => {
    render(tooltip);
    tooltip.classList.remove("hidden");
    const rect = el.getBoundingClientRect();
    const tip = tooltip.getBoundingClientRect();
    const left = Math.min(Math.max(8, rect.left + rect.width / 2 - tip.width / 2), window.innerWidth - tip.width - 8);
    tooltip.style.left = `${left}px`;
    tooltip.style.top = `${rect.bottom + 8}px`;
  });
  el.addEventListener("mouseleave", () => tooltip.classList.add("hidden"));
}

function starSvg() {
  const size = 3;
  const rects = STAR.flatMap((row, y) =>
    [...row].map((char, x) =>
      char === "G" ? `<rect x="${x * size}" y="${y * size}" width="${size}" height="${size}"/>` : ""
    )
  );
  const width = STAR[0].length * size;
  return `<svg width="${width}" height="${width}" viewBox="0 0 ${width} ${width}" shape-rendering="crispEdges" fill="rgb(var(--color-brand))" aria-hidden="true">${rects.join("")}</svg>`;
}

function renderStar(best) {
  const label = `You beat the Kong docs game in ${formatTime(best)}. Kong is hiring!`;
  headerLogos().forEach((logo) => {
    let star = logo.nextElementSibling;
    if (!star?.classList.contains(STAR_CLASS)) {
      star = document.createElement("a");
      star.href = CAREERS_URL;
      star.target = "_blank";
      star.rel = "noopener";
      star.className = `${STAR_CLASS} inline-flex items-center no-icon`;
      star.innerHTML = starSvg();
      logo.after(star);
      attachTooltip(star, (tooltip) => (tooltip.textContent = star.dataset.label));
      star.addEventListener("click", () => track("Arcade Careers Clicked", { source: "header-star" }));
    }
    star.dataset.label = label;
    star.setAttribute("aria-label", label);
  });
}

// Saves the run and returns the best time so far.
export function recordWin(seconds) {
  const record = readRecord();
  const best = record?.best ? Math.min(record.best, seconds) : seconds;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ best }));
  } catch {
    // Private browsing: the star still shows for this page view.
  }
  renderStar(best);
  return best;
}

export function initTrophy() {
  headerLogos().forEach((logo) => attachTooltip(logo, renderHint));
  const record = readRecord();
  if (record?.best) renderStar(record.best);
}
