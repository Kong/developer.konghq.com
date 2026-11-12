import test from "node:test";
import assert from "node:assert/strict";
import { chromium } from "playwright";
import { generateInstructionFiles } from "../instructions/extractor.js";

const CLIPBOARD = ["clipboard-read", "clipboard-write"];

const CONFIG = {
  instructionsDir: "input/instructions",
  productionUrl: "https://developer.konghq.com",
  products: {},
};

// Replaces the browser with a context that records what it was granted. The
// extraction itself is not under test here, so the stub page refuses to
// navigate: extractInstructionsFromURL logs that failure and moves on.
function stubBrowser(t) {
  const granted = [];
  const page = {
    goto: async () => {
      throw new Error("stub page: navigation is not part of this test");
    },
    close: async () => {},
  };
  const context = {
    async grantPermissions(permissions, options) {
      granted.push({ permissions, origin: options.origin });
    },
    async newPage() {
      return page;
    },
  };

  t.mock.method(chromium, "launch", async () => ({
    newContext: async () => context,
    close: async () => {},
  }));
  t.mock.method(console, "log", () => {});
  t.mock.method(console, "error", () => {});

  return granted;
}

test("the clipboard permission is granted once per origin the run visits", async (t) => {
  const granted = stubBrowser(t);

  await generateInstructionFiles(
    [
      "http://localhost:8898/how-to/first/",
      "http://localhost:8888/how-to/second/",
      "http://localhost:8898/how-to/third/",
    ],
    CONFIG,
  );

  assert.deepEqual(granted, [
    { permissions: CLIPBOARD, origin: "http://localhost:8898" },
    { permissions: CLIPBOARD, origin: "http://localhost:8888" },
  ]);
});

test("a run with no URL grants the clipboard permission to nothing", async (t) => {
  const granted = stubBrowser(t);

  await generateInstructionFiles([], CONFIG);

  assert.deepEqual(granted, []);
});

test("a malformed URL fails before the browser launches", async (t) => {
  let launches = 0;
  t.mock.method(chromium, "launch", async () => {
    launches += 1;
    throw new Error("the browser must not launch for a malformed URL");
  });

  await assert.rejects(
    () => generateInstructionFiles(["not a url"], CONFIG),
    /not a url/,
  );
  assert.equal(launches, 0);
});
