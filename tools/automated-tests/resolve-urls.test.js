import { test, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import fs from "fs/promises";
import os from "os";
import path from "path";
import yaml from "js-yaml";
import matter from "gray-matter";
import { resolveUrlsToTest } from "./resolve-urls.js";

const config = {
  baseUrl: "http://localhost:8888",
  productionUrl: "https://developer.konghq.com",
};

const FIXTURES = path.join(import.meta.dirname, "fixtures/how-tos");

let tmpRoot;
let workDir;
let originalCwd;

before(async () => {
  originalCwd = process.cwd();
  tmpRoot = await fs.mkdtemp(path.join(os.tmpdir(), "resolve-urls-"));

  // The full scan globs "../../app/_how-tos/**/*" relative to the working
  // directory, so the fake repo needs the same two levels of nesting.
  workDir = path.join(tmpRoot, "tools/automated-tests");
  await fs.mkdir(workDir, { recursive: true });
  await fs.mkdir(path.join(tmpRoot, "app"), { recursive: true });
  await fs.cp(FIXTURES, path.join(tmpRoot, "app/_how-tos"), {
    recursive: true,
  });

  process.chdir(workDir);
});

after(async () => {
  process.chdir(originalCwd);
  await fs.rm(tmpRoot, { recursive: true, force: true });
});

beforeEach(async () => {
  await fs.rm(path.join(workDir, ".automated-tests"), { force: true });
});

async function readManifest() {
  return fs.readFile(path.join(workDir, ".automated-tests"), "utf-8");
}

test("explicit URLs pass straight through", async () => {
  const result = await resolveUrlsToTest(
    { urls: "http://localhost:8888/how-to/anything/" },
    config,
  );

  assert.deepEqual(result.urlsToTest, ["http://localhost:8888/how-to/anything/"]);
  assert.equal(result.haltOnSeriesError, true);
  await assert.rejects(readManifest, { code: "ENOENT" });
});

test("explicit URLs accept a list", async () => {
  const result = await resolveUrlsToTest({ urls: ["one", "two"] }, config);

  assert.deepEqual(result.urlsToTest, ["one", "two"]);
});

test("explicit URLs and a product together are rejected", async () => {
  await assert.rejects(
    () => resolveUrlsToTest({ urls: "one", product: "event-gateway" }, config),
    /Pass either --urls or --product, not both\./,
  );
});

test("the full scan excludes every kind of non-testable how-to", async () => {
  const { urlsToTest, haltOnSeriesError } = await resolveUrlsToTest({}, config);

  assert.deepEqual(urlsToTest.sort(), [
    "http://localhost:8888/how-to/event-gateway/no-permalink/",
    "http://localhost:8888/how-to/series-first/",
    "http://localhost:8888/how-to/testable/",
    // A frozen version folder is in scope for the full scan, unlike the
    // product scan.
    "http://localhost:8888/how-to/v1/frozen/",
  ]);
  assert.equal(haltOnSeriesError, true);
});

test("the full scan records its exclusions in the skip manifest", async () => {
  await resolveUrlsToTest({}, config);
  const manifest = await readManifest();

  assert.match(manifest, /Tagged with automated_tests=false/);
  assert.match(manifest, /Tagged with published=false/);
  assert.match(manifest, /Part of series "egw-series", tested via "Series first"/);
  assert.match(manifest, /Tagged with @todo\./);
});

test("explicit files are filtered the same way as the full scan", async () => {
  const { urlsToTest } = await resolveUrlsToTest(
    {
      files: [
        "../../app/_how-tos/event-gateway/testable.md",
        "../../app/_how-tos/event-gateway/tests-disabled.md",
      ],
    },
    config,
  );

  assert.deepEqual(urlsToTest, ["http://localhost:8888/how-to/testable/"]);
});

test("an explicit non-first series page is a hard error", async () => {
  await assert.rejects(
    () =>
      resolveUrlsToTest(
        { files: "../../app/_how-tos/event-gateway/series-second.md" },
        config,
      ),
    /is part of series "egw-series" but is not the first page/,
  );
});

test("the product run applies the same testability rules as the full scan", async () => {
  const { urlsToTest, haltOnSeriesError } = await resolveUrlsToTest(
    { product: "event-gateway" },
    config,
    { repoRoot: tmpRoot },
  );

  assert.deepEqual(urlsToTest.sort(), [
    // No permalink in frontmatter, so the URL is derived from the file path.
    "http://localhost:8888/how-to/event-gateway/no-permalink/",
    "http://localhost:8888/how-to/series-first/",
    "http://localhost:8888/how-to/testable/",
  ]);
  assert.equal(haltOnSeriesError, false);
});

test("the product run excludes frozen version folders", async () => {
  const { urlsToTest } = await resolveUrlsToTest(
    { product: "event-gateway" },
    config,
    { repoRoot: tmpRoot },
  );

  assert.equal(
    urlsToTest.some((url) => url.includes("/v1/")),
    false,
  );
});

test("the product run records its exclusions in the skip manifest", async () => {
  await resolveUrlsToTest({ product: "event-gateway" }, config, {
    repoRoot: tmpRoot,
  });
  const manifest = yaml.load(await readManifest());

  assert.deepEqual(
    manifest.map((entry) => [entry.name, entry.message]).sort(),
    [
      [
        "[Series second](https://developer.konghq.com/how-to/series-second/)",
        'Part of series "egw-series", tested via "Series first"',
      ],
      [
        "[Tests disabled](https://developer.konghq.com/how-to/tests-disabled/)",
        "Tagged with automated_tests=false",
      ],
      [
        "[Todo](https://developer.konghq.com/how-to/todo/)",
        "Tagged with @todo.",
      ],
      [
        "[Unpublished](https://developer.konghq.com/how-to/unpublished/)",
        "Tagged with published=false",
      ],
    ],
  );
});

test("the product run's manifest describes only that run", async () => {
  await resolveUrlsToTest({}, config);
  await resolveUrlsToTest({ product: "event-gateway" }, config, {
    repoRoot: tmpRoot,
  });
  const manifest = yaml.load(await readManifest());

  assert.equal(
    manifest.some((entry) => entry.name.includes("/v1/")),
    false,
  );
});

test("the product run ignores a base URL argument and uses the config", async () => {
  const { urlsToTest } = await resolveUrlsToTest(
    { product: "event-gateway", baseUrl: "http://example.test" },
    config,
    { repoRoot: tmpRoot },
  );

  assert.equal(
    urlsToTest.every((url) => url.startsWith(config.baseUrl)),
    true,
  );
});

test("the product run and the full scan agree on the same folder", async () => {
  const { urlsToTest: fromProduct } = await resolveUrlsToTest(
    { product: "event-gateway" },
    config,
    { repoRoot: tmpRoot },
  );
  const { urlsToTest: fromFullScan } = await resolveUrlsToTest({}, config);

  // The full scan keeps frozen version folders; the product run drops them.
  const frozen = matter.read(
    path.join(tmpRoot, "app/_how-tos/event-gateway/v1/frozen.md"),
  );
  const frozenUrl = `${config.baseUrl}${frozen.data.permalink}`;

  assert.ok(fromFullScan.includes(frozenUrl));
  assert.deepEqual(
    fromProduct.sort(),
    fromFullScan.filter((url) => url !== frozenUrl).sort(),
  );
});

test("an unknown product is an error", async () => {
  await assert.rejects(
    () => resolveUrlsToTest({ product: "nope" }, config, { repoRoot: tmpRoot }),
    /No such directory/,
  );
});

async function captureLogs(run) {
  const lines = [];
  const originalLog = console.log;
  console.log = (...args) => lines.push(args.join(" "));
  try {
    await run();
  } finally {
    console.log = originalLog;
  }
  return lines;
}

test("the full scan logs how-tos that name no testable product", async () => {
  const lines = await captureLogs(() => resolveUrlsToTest({}, config));

  assert.ok(
    lines.includes(
      "Skipping file: app/_how-tos/event-gateway/untagged.md. " +
      "No products in frontmatter, so nothing to test",
    ),
  );
  assert.ok(
    lines.includes(
      "Skipping file: app/_how-tos/event-gateway/other-product.md. " +
      "Products (mesh) include no testable product",
    ),
  );
});

test("the product run logs the same how-tos as the full scan", async () => {
  const fromProduct = await captureLogs(() =>
    resolveUrlsToTest({ product: "event-gateway" }, config, {
      repoRoot: tmpRoot,
    }),
  );
  const fromFullScan = await captureLogs(() => resolveUrlsToTest({}, config));

  const untestableLogLines = (lines) =>
    lines.filter(
      (line) =>
        line.includes("untagged.md") ||
        line.includes("other-product.md"),
    );

  assert.deepEqual(
    untestableLogLines(fromProduct).sort(),
    untestableLogLines(fromFullScan).sort(),
  );
  assert.equal(untestableLogLines(fromProduct).length, 2);
});

test("a how-to with no testable product stays out of the URL list", async () => {
  const { urlsToTest } = await resolveUrlsToTest({}, config);

  assert.equal(
    urlsToTest.some(
      (url) =>
        url.includes("untagged") ||
        url.includes("other-product"),
    ),
    false,
  );
});
