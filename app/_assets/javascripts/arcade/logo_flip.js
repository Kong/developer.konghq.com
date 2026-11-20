// Hover the header logo for a few seconds and it flips to show the Konami
// code, a nudge that the arcade exists. Design notes: docs/arcade.md.

import { headerLogos } from "./trophy";

const HOVER_MS = 3000;
const CODE = ["↑", "↑", "↓", "↓", "←", "→", "←", "→", "B", "A"];

function addBackFace(logo) {
  const back = document.createElement("span");
  back.className = "logo-flip-back";
  back.setAttribute("aria-hidden", "true");
  const code = document.createElement("span");
  code.className = "logo-flip-code";
  CODE.forEach((key) => {
    const item = document.createElement("span");
    item.textContent = key;
    code.append(item);
  });
  back.append(code);
  logo.append(back);
}

export function initLogoFlip() {
  headerLogos().forEach((logo) => {
    let timer;
    logo.classList.add("logo-flip");
    addBackFace(logo);

    const reset = () => {
      clearTimeout(timer);
      logo.classList.remove("is-flipped");
    };

    logo.addEventListener("mouseenter", () => {
      clearTimeout(timer);
      timer = setTimeout(() => {
        logo.classList.add("is-flipped");
      }, HOVER_MS);
    });
    logo.addEventListener("mouseleave", reset);
    // A mouse click also focuses the link, so flip on keyboard focus only.
    logo.addEventListener("focus", () => {
      if (logo.matches(":focus-visible")) logo.classList.add("is-flipped");
    });
    logo.addEventListener("blur", reset);
  });
}
