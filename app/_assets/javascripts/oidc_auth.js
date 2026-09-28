const storageKey = "oidc_id_token";
const preferredNameStorageKey = "oidc_preferred_name";
const organizationNameStorageKey = "oidc_organization_name";

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
  if (!login || !greeting || !logout) return;

  const loginUrl = new URL("/auth/login", location.origin);
  loginUrl.searchParams.set("return_to", `${location.pathname}${location.search}${location.hash}`);
  login.href = loginUrl.href;

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
    login.classList.toggle("hidden", Boolean(identity));
    greeting.classList.toggle("hidden", !identity);
    logout.classList.toggle("hidden", !identity);
    if (identity) {
      expiryTimer = setTimeout(render, Math.min(identity.expiresAt - Date.now() + 100, 2_147_483_647));
    }
  }

  logout.addEventListener("click", () => {
    try {
      localStorage.removeItem(storageKey);
      localStorage.removeItem(preferredNameStorageKey);
      localStorage.removeItem(organizationNameStorageKey);
    } catch { /* storage unavailable */ }
    render();
  });
  window.addEventListener("storage", (event) => {
    if ([storageKey, preferredNameStorageKey, organizationNameStorageKey, null].includes(event.key)) render();
  });
  window.addEventListener("pageshow", render);
  render();
});
