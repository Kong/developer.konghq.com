// Hidden arcade game. Typing the code loads the game chunk on demand, so
// regular page views only pay for this listener and the header trophy.
// Design notes and handoff: docs/arcade.md.
import { initTrophy } from "./arcade/trophy";
import { track } from "./arcade/analytics";

const CODES = [
  ["0", "4", "5", "1"],
  ["arrowup", "arrowup", "arrowdown", "arrowdown", "arrowleft", "arrowright", "arrowleft", "arrowright", "b", "a", " "],
];
// The whole code must be typed within this window, measured from its first key.
const WINDOW_MS = 10000;
const MAX_LENGTH = Math.max(...CODES.map((code) => code.length));
const EDITABLE = "input, textarea, select, [contenteditable]:not([contenteditable='false'])";

let keys = [];
let active = false;

initTrophy();

function matches(code) {
  const typed = keys.slice(-code.length);
  return (
    typed.length === code.length &&
    typed.every(({ key }, i) => key === code[i]) &&
    typed[typed.length - 1].time - typed[0].time <= WINDOW_MS
  );
}

document.addEventListener("keydown", (event) => {
  if (active || event.repeat || event.metaKey || event.ctrlKey || event.altKey) return;
  if (event.target instanceof Element && event.target.closest(EDITABLE)) return;

  if (event.key === "Shift") return;

  keys = [...keys, { key: event.key.toLowerCase(), time: event.timeStamp }].slice(-MAX_LENGTH);
  if (!CODES.some(matches)) return;

  keys = [];
  active = true;
  track("Arcade Started");
  import("./arcade/game.js")
    .then(({ start }) => start({ onExit: () => (active = false) }))
    .catch((error) => {
      console.error(error);
      active = false;
    });
});
