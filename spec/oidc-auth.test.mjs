import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import vm from "node:vm";

test("how-to selection updates copied control plane commands and logout restores them", () => {
  const listeners = new Map();
  const storage = new Map();
  const elements = Object.fromEntries([
    "oidc-login", "oidc-greeting", "oidc-logout",
    "how-to-control-plane-picker", "how-to-control-plane-field",
  ].map((id) => [id, {
    textContent: "",
    classList: { toggle() {} },
    setAttribute() {},
    addEventListener(type, listener) { listeners.set(`${id}:${type}`, listener); },
    replaceChildren() { this.options = []; },
    append(option) { this.options.push(option); },
  }]));

  const placeholders = [
    '"your-control-plane-id"', "'YOUR-CONTROL-PLANE-ID'",
    "'YOUR CONTROL PLANE ID'", "'YOUR_CONTROL_PLANE_ID'", "YOUR-GENERATED-ID-HERE",
  ];
  const lines = placeholders.map((placeholder) => {
    const originalText = `export CONTROL_PLANE_ID=${placeholder}`;
    const originalMarkup = `<span>${originalText}</span>`;
    let lineMarkup = originalMarkup;
    let lineText = originalText;
    const line = {
      get innerHTML() { return lineMarkup; },
      set innerHTML(value) { lineMarkup = value; lineText = originalText; },
      get textContent() { return lineText; },
      set textContent(value) { lineText = value; lineMarkup = value; },
      querySelectorAll: () => [],
    };
    return { line, originalMarkup };
  });

  const token = `header.${Buffer.from(JSON.stringify({
    sub: "user-123", exp: Math.floor(Date.now() / 1000) + 300,
  })).toString("base64url")}.signature`;
  storage.set("oidc_id_token", token);
  storage.set("oidc_control_planes", JSON.stringify({
    sub: "user-123",
    items: [{ id: "cp-1", name: "Alpha" }, { id: "cp-2", name: "Beta" }],
    activeId: "cp-1",
    error: false,
  }));

  const context = {
    document: {
      getElementById: (id) => elements[id] || null,
      querySelectorAll: () => lines.map(({ line }) => line),
      addEventListener(type, listener) { listeners.set(type, listener); },
      createElement: () => ({ value: "", textContent: "" }),
    },
    window: { addEventListener(type, listener) { listeners.set(type, listener); } },
    localStorage: {
      getItem: (key) => storage.get(key) ?? null,
      setItem: (key, value) => storage.set(key, value),
      removeItem: (key) => storage.delete(key),
    },
    location: { origin: "http://localhost:8888", pathname: "/how-to/automate-api-catalog/", search: "", hash: "" },
    URL, atob, Date,
    setTimeout: () => 1,
    clearTimeout: () => {},
  };
  vm.runInNewContext(readFileSync("app/_assets/javascripts/oidc_auth.js", "utf8"), context);
  listeners.get("DOMContentLoaded")();

  for (const { line } of lines) {
    assert.equal(line.textContent, 'export CONTROL_PLANE_ID="cp-1" # Alpha');
  }
  assert.deepEqual(elements["how-to-control-plane-picker"].options.map((option) => option.value), ["cp-1", "cp-2"]);
  elements["how-to-control-plane-picker"].value = "cp-2";
  listeners.get("how-to-control-plane-picker:change")({ currentTarget: elements["how-to-control-plane-picker"] });
  for (const { line } of lines) {
    assert.equal(line.textContent, 'export CONTROL_PLANE_ID="cp-2" # Beta');
  }
  assert.equal(JSON.parse(storage.get("oidc_control_planes")).activeId, "cp-2");

  listeners.get("oidc-logout:click")();
  for (const { line, originalMarkup } of lines) {
    assert.equal(line.innerHTML, originalMarkup);
  }
  assert.equal(storage.has("oidc_control_planes"), false);
  assert.equal(elements["how-to-control-plane-picker"].disabled, true);
  assert.equal(elements["how-to-control-plane-picker"].options[0].textContent,
    "Log in to choose a control plane");
});
