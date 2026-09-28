const storageKey = "oidc_id_token";
const preferredNameStorageKey = "oidc_preferred_name";
const organizationNameStorageKey = "oidc_organization_name";
const controlPlanesStorageKey = "oidc_control_planes";
const controlPlanePlaceholders = new Set([
  '"your-control-plane-id"',
  "'YOUR-CONTROL-PLANE-ID'",
  "'YOUR CONTROL PLANE ID'",
  "'YOUR_CONTROL_PLANE_ID'",
  "YOUR-GENERATED-ID-HERE",
]);

function controlPlaneState(subject) {
  if (!subject) return null;
  try {
    const state = JSON.parse(localStorage.getItem(controlPlanesStorageKey));
    if (state?.sub !== subject || !Array.isArray(state.items)) return null;
    const items = state.items.filter((item) =>
      typeof item.id === "string" && /^[A-Za-z0-9_-]+$/.test(item.id) &&
      typeof item.name === "string" && item.name.trim()
    );
    return {
      ...state,
      items,
      active: items.find((item) => item.id === state.activeId) || items[0] || null,
    };
  } catch {
    return null;
  }
}

function identityFromToken(token) {
  try {
    const payload = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
    if (typeof payload.sub === "string" && payload.sub &&
        typeof payload.exp === "number" && payload.exp > Date.now() / 1000) {
      return { sub: payload.sub, expiresAt: payload.exp * 1000 };
    }
  } catch {
    // Malformed or unavailable token storage is treated as logged out.
  }
  return null;
}

document.addEventListener("DOMContentLoaded", () => {
  const login = document.getElementById("oidc-login");
  const greeting = document.getElementById("oidc-greeting");
  const logout = document.getElementById("oidc-logout");
  const heroName = document.getElementById("oidc-hero-name");
  const howToControlPlaneSelect = document.getElementById("how-to-control-plane-picker");
  const howToControlPlaneField = document.getElementById("how-to-control-plane-field");
  if (!login || !greeting || !logout) return;

  const controlPlaneLines = [...document.querySelectorAll("pre code .line")].flatMap((line) => {
    const match = line.textContent.match(/^(\s*)export CONTROL_PLANE_ID=("[^"]+"|'[^']+'|[A-Z-]+)\s*$/);
    return match && controlPlanePlaceholders.has(match[2])
      ? [{ line, originalMarkup: line.innerHTML, indent: match[1], placeholder: match[2] }]
      : [];
  });

  const loginUrl = new URL("/auth/login", location.origin);
  loginUrl.searchParams.set("return_to", `${location.pathname}${location.search}${location.hash}`);
  login.href = loginUrl.href;

  function populateControlPlaneSelect(select, controlPlanes, active, emptyLabel = "No control planes available") {
    select.replaceChildren();
    select.disabled = !active;
    if (!active) {
      const option = document.createElement("option");
      option.value = "";
      option.textContent = emptyLabel;
      select.append(option);
      return;
    }
    for (const item of controlPlanes?.items || []) {
      const option = document.createElement("option");
      option.value = item.id;
      option.textContent = item.name;
      select.append(option);
    }
    if (active) select.value = active.id;
  }

  let expiryTimer;
  function render() {
    clearTimeout(expiryTimer);
    let identity = null;
    try {
      const token = localStorage.getItem(storageKey);
      identity = token && identityFromToken(token);
      if (token && !identity) {
        localStorage.removeItem(storageKey);
        localStorage.removeItem(preferredNameStorageKey);
        localStorage.removeItem(organizationNameStorageKey);
        localStorage.removeItem(controlPlanesStorageKey);
      }
    } catch {
      // Private browsing settings can make localStorage unavailable.
    }

    let preferredName = null;
    let organizationName = null;
    if (identity) {
      try {
        preferredName = localStorage.getItem(preferredNameStorageKey);
        organizationName = localStorage.getItem(organizationNameStorageKey);
      } catch { /* storage unavailable */ }
    }

    greeting.textContent = identity
      ? (preferredName
        ? `Hello ${preferredName}${organizationName ? ` from ${organizationName}` : ""}`
        : identity.sub)
      : "";
    greeting.title = greeting.textContent;
    greeting.setAttribute("aria-label", greeting.textContent);
    const firstName = preferredName?.trim().split(/\s+/)[0];
    if (heroName) heroName.textContent = identity && firstName ? ` ${firstName}` : "";

    const controlPlanes = controlPlaneState(identity?.sub);
    const active = controlPlanes?.active;
    for (const { line, originalMarkup, indent, placeholder } of controlPlaneLines) {
      if (active) {
        const commentText = ` # ${active.name.replace(/[\r\n]+/g, " ")}`;
        const command = `${indent}export CONTROL_PLANE_ID="${active.id}"${commentText}`;
        if (line.textContent === command) continue;
        line.innerHTML = originalMarkup;
        const value = [...line.querySelectorAll("span")].find((span) =>
          span.textContent.includes(placeholder)
        );
        if (value) {
          value.textContent = value.textContent.replace(placeholder, `"${active.id}"`);
          const comment = document.createElement("span");
          comment.className = "text-terciary";
          comment.textContent = commentText;
          line.append(comment);
        } else {
          line.textContent = command;
        }
      } else if (line.innerHTML !== originalMarkup) {
        line.innerHTML = originalMarkup;
      }
    }
    if (howToControlPlaneSelect && howToControlPlaneField) {
      const emptyLabel = !identity
        ? "Log in to choose a control plane"
        : controlPlanes?.error ? "Control planes unavailable" : "No control planes available";
      populateControlPlaneSelect(howToControlPlaneSelect, controlPlanes, active, emptyLabel);
    }
    login.classList.toggle("hidden", Boolean(identity));
    greeting.classList.toggle("hidden", !identity);
    logout.classList.toggle("hidden", !identity);
    if (identity) {
      expiryTimer = setTimeout(render, Math.min(identity.expiresAt - Date.now() + 100, 2_147_483_647));
    }
  }

  function selectControlPlane(event) {
    try {
      const identity = identityFromToken(localStorage.getItem(storageKey));
      const state = controlPlaneState(identity?.sub);
      const selectedId = event.currentTarget.value;
      if (!state?.items.some((item) => item.id === selectedId)) return;
      localStorage.setItem(controlPlanesStorageKey, JSON.stringify({
        sub: identity.sub,
        items: state.items,
        activeId: selectedId,
        error: false,
      }));
      render();
    } catch { /* storage unavailable */ }
  }

  howToControlPlaneSelect?.addEventListener("change", selectControlPlane);

  logout.addEventListener("click", () => {
    try {
      localStorage.removeItem(storageKey);
      localStorage.removeItem(preferredNameStorageKey);
      localStorage.removeItem(organizationNameStorageKey);
      localStorage.removeItem(controlPlanesStorageKey);
    } catch { /* storage unavailable */ }
    render();
  });
  window.addEventListener("storage", (event) => {
    if ([storageKey, preferredNameStorageKey, organizationNameStorageKey, controlPlanesStorageKey, null].includes(event.key)) render();
  });
  window.addEventListener("pageshow", render);
  render();
});
