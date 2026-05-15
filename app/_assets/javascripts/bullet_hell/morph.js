import { computeFormation } from "./game";

const MORPH_DURATION = 900;
const ENEMY_SIZE = 48;
const ICON_EXCLUDE_ANCESTORS =
  "header, nav, footer, [class*='logo'], [class*='top-nav'], [class*='social'], [class*='copy'], button";
const MIN_ICON_SIZE = 20;

export function morph() {
  const svgs = Array.from(document.querySelectorAll("svg")).filter((el) => {
    if (el.closest(ICON_EXCLUDE_ANCESTORS)) return false;
    const r = el.getBoundingClientRect();
    return (
      r.width >= MIN_ICON_SIZE &&
      r.height >= MIN_ICON_SIZE &&
      r.bottom > 0 &&
      r.top < window.innerHeight &&
      r.right > 0 &&
      r.left < window.innerWidth
    );
  });

  const captured = svgs.map((el) => {
    const rect = el.getBoundingClientRect();
    return { el, rect, html: serializeSvg(el) };
  });

  for (const c of captured) c.el.style.visibility = "hidden";

  const overlay = document.createElement("div");
  overlay.style.cssText =
    "position:fixed;inset:0;z-index:9999;pointer-events:none;overflow:hidden";
  document.body.appendChild(overlay);

  const formation = computeFormation(captured.length, window.innerWidth, window.innerHeight);

  const clones = captured.map(({ rect, html }, i) => {
    const wrap = document.createElement("div");
    wrap.style.cssText = [
      "position:absolute",
      `left:${rect.left}px`,
      `top:${rect.top}px`,
      `width:${rect.width}px`,
      `height:${rect.height}px`,
      `transition:transform ${MORPH_DURATION}ms cubic-bezier(0.4, 0, 0.2, 1), opacity 200ms ease-out ${MORPH_DURATION - 100}ms`,
      `transition-delay:${i * 15}ms, ${i * 15 + MORPH_DURATION - 100}ms`,
      "will-change:transform,opacity",
    ].join(";");
    wrap.innerHTML = html;
    const svg = wrap.querySelector("svg");
    if (svg) {
      svg.setAttribute("width", String(rect.width));
      svg.setAttribute("height", String(rect.height));
      svg.style.width = "100%";
      svg.style.height = "100%";
    }
    overlay.appendChild(wrap);
    return { wrap, rect };
  });

  return new Promise((resolve) => {
    requestAnimationFrame(() => {
      clones.forEach(({ wrap, rect }, i) => {
        const slot = formation[i];
        const tx = slot.x - (rect.left + rect.width / 2);
        const ty = slot.y - (rect.top + rect.height / 2);
        const scale = ENEMY_SIZE / Math.max(rect.width, rect.height);
        wrap.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`;
      });

      setTimeout(() => {
        for (const { wrap } of clones) wrap.style.opacity = "0";
      }, MORPH_DURATION + clones.length * 15 - 100);

      const total = MORPH_DURATION + clones.length * 15 + 200;
      setTimeout(() => {
        overlay.remove();
        const sprites = captured.map(({ html }) => svgToImage(html));
        resolve({
          sprites,
          restore: () => {
            for (const c of captured) c.el.style.visibility = "";
          },
        });
      }, total);
    });
  });
}

function serializeSvg(el) {
  const clone = el.cloneNode(true);
  if (!clone.getAttribute("xmlns")) {
    clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
  }
  return new XMLSerializer().serializeToString(clone);
}

function svgToImage(html) {
  const img = new Image();
  try {
    img.src = `data:image/svg+xml;base64,${btoa(unescape(encodeURIComponent(html)))}`;
  } catch (_) {
    img.src = "data:image/svg+xml;utf8," + encodeURIComponent(html);
  }
  return img;
}
