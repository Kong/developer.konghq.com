// Loaded on every page with the trigger. Adds the hint tooltip to the header
// logo and, once the arcade has been beaten, a pixel star beside it that
// links to Kong careers and shows the best time.

const STORAGE_KEY = "kong-docs-arcade";
const HINT = "This game is very #immersive#...";
const STAR_ID = "arcade-star";
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

function headerLogo() {
  return document.querySelector("#header-nav a[href='/']");
}

// Mirrors the site's [data-tooltip] behaviour, which only binds elements
// present at page load; the star can appear later.
function attachTooltip(el, getText) {
  const tooltip = document.getElementById("tooltip");
  if (!tooltip || "ontouchstart" in window || navigator.maxTouchPoints > 0) return;

  el.addEventListener("mouseenter", () => {
    tooltip.textContent = getText();
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
  const logo = headerLogo();
  if (!logo) return;

  let star = document.getElementById(STAR_ID);
  if (!star) {
    star = document.createElement("a");
    star.id = STAR_ID;
    star.href = CAREERS_URL;
    star.target = "_blank";
    star.rel = "noopener";
    star.className = "inline-flex items-center no-icon";
    star.innerHTML = starSvg();
    logo.after(star);
    attachTooltip(star, () => star.dataset.label);
  }
  star.dataset.label = `You beat the Kong docs game in ${formatTime(best)}. Kong is hiring!`;
  star.setAttribute("aria-label", star.dataset.label);
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
  const logo = headerLogo();
  if (!logo) return;
  attachTooltip(logo, () => HINT);
  const record = readRecord();
  if (record?.best) renderStar(record.best);
}
