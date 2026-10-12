// Hidden arcade game. Typing the code loads the game chunk on demand, so
// regular page views only pay for this listener.
const CODE = "0451";
const EDITABLE = "input, textarea, select, [contenteditable]:not([contenteditable='false'])";

let buffer = "";
let active = false;

document.addEventListener("keydown", (event) => {
  if (active || event.repeat || event.metaKey || event.ctrlKey || event.altKey) return;
  if (event.target instanceof Element && event.target.closest(EDITABLE)) return;

  if (!/^[0-9]$/.test(event.key)) {
    buffer = "";
    return;
  }

  buffer = (buffer + event.key).slice(-CODE.length);
  if (buffer !== CODE) return;

  buffer = "";
  active = true;
  import("./arcade/game.js")
    .then(({ start }) => start({ onExit: () => (active = false) }))
    .catch((error) => {
      console.error(error);
      active = false;
    });
});
