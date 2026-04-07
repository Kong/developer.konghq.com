const KONAMI_SEQUENCE = [
  "ArrowUp",
  "ArrowUp",
  "ArrowDown",
  "ArrowDown",
  "ArrowLeft",
  "ArrowRight",
  "ArrowLeft",
  "ArrowRight",
  "b",
  "a",
];

const KONAMI_OVERRIDES = {
  "--color-brand": "204, 255, 0",
  "--color-brand-saturated": "204, 255, 0",
  "--color-bg-primary": "0, 15, 6",
  "--color-bg-secondary": "0, 26, 12",
  "--color-bg-terciary": "0, 37, 18",
  "--color-bg-code-block": "0, 26, 12",
  "--color-bg-code-block-header": "0, 37, 18",
  "--color-bg-hover-component": "0, 37, 18",
  "--color-text-primary": "255, 255, 255",
  "--color-text-secondary": "183, 189, 181",
  "--color-text-terciary": "183, 189, 181",
  "--color-border-primary": "204, 255, 0",
  "--color-shadow-primary": "204, 255, 0, 0.04",
  "--color-shadow-hover-card": "204, 255, 0, 0.16",

  // Semantic colors — primary (borders/icons), secondary (backgrounds)
  "--color-semantic-red-primary": "255, 100, 100",
  "--color-semantic-red-secondary": "80, 20, 20",
  "--color-semantic-yellow-secondary": "75, 55, 10",
  "--color-semantic-blue-primary": "204, 255, 0",
  "--color-semantic-blue-secondary": "30, 50, 0",
  "--color-semantic-green-secondary": "10, 65, 35",
  "--color-semantic-grey-secondary": "55, 65, 55",
  "--color-semantic-purple-secondary": "60, 30, 90",
  "--color-semantic-orange-secondary": "85, 50, 15",
  "--color-semantic-teal-secondary": "15, 60, 70",
};

const STORAGE_KEY = "konami";

function applyKonamiTheme() {
  const root = document.documentElement;
  for (const [property, value] of Object.entries(KONAMI_OVERRIDES)) {
    root.style.setProperty(property, value);
  }
  root.style.setProperty("color-scheme", "dark");
  root.classList.add("konami");
}

function removeKonamiTheme() {
  const root = document.documentElement;
  for (const property of Object.keys(KONAMI_OVERRIDES)) {
    root.style.removeProperty(property);
  }
  const isDarkMode = root.classList.contains("dark");
  root.style.setProperty("color-scheme", isDarkMode ? "dark" : "light");
  root.classList.remove("konami");
}

function isActive() {
  return localStorage.getItem(STORAGE_KEY) === "active";
}

function toggle() {
  if (isActive()) {
    localStorage.removeItem(STORAGE_KEY);
    removeKonamiTheme();
  } else {
    localStorage.setItem(STORAGE_KEY, "active");
    applyKonamiTheme();
  }
}

document.addEventListener("DOMContentLoaded", function () {
  if (isActive()) {
    applyKonamiTheme();
  }

  let position = 0;

  document.addEventListener("keydown", function (e) {
    if (e.key === KONAMI_SEQUENCE[position]) {
      position++;
      if (position === KONAMI_SEQUENCE.length) {
        toggle();
        position = 0;
      }
    } else {
      position = 0;
    }
  });
});
