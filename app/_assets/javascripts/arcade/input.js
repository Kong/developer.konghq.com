// Keyboard state for the fixed-step loop: `held` lasts while a key is down,
// `pressed` lasts for the physics step after the press.

const KEYS = {
  left: ["ArrowLeft", "KeyA"],
  right: ["ArrowRight", "KeyD"],
  jump: ["Space", "ArrowUp", "KeyW"],
  down: ["ArrowDown", "KeyS"],
  use: ["KeyE"],
};

// Physical key code, falling back to the key value for synthetic or virtual
// keyboards that leave event.code empty.
export function keyCode(event) {
  if (event.code) return event.code;
  if (event.key === " ") return "Space";
  if (/^[a-z]$/i.test(event.key)) return `Key${event.key.toUpperCase()}`;
  return event.key;
}

export class Input {
  constructor() {
    this.held = new Set();
    this.pressed = new Set();
  }

  press(code, repeat) {
    if (!repeat) this.pressed.add(code);
    this.held.add(code);
  }

  release(code) {
    this.held.delete(code);
  }

  // Window blur: keys released elsewhere never send keyup here.
  releaseAll() {
    this.held.clear();
  }

  endStep() {
    this.pressed.clear();
  }

  anyPressed() {
    return this.pressed.size > 0;
  }

  isHeld(action) {
    return KEYS[action].some((code) => this.held.has(code));
  }

  wasPressed(action) {
    return KEYS[action].some((code) => this.pressed.has(code));
  }
}
