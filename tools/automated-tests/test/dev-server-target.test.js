import test from "node:test";
import assert from "node:assert/strict";
import fs from "fs/promises";
import os from "os";
import path from "path";
import { resolveDevServerTarget, visitedOrigins } from "../dev-server-target.js";
import { testeableUrlsFromFiles } from "../instructions-file.js";

function withEnv(vars, fn) {
  const previous = process.env.BASE_URL;
  delete process.env.BASE_URL;
  if (vars.BASE_URL !== undefined) {
    process.env.BASE_URL = vars.BASE_URL;
  }

  return Promise.resolve()
    .then(fn)
    .finally(() => {
      if (previous === undefined) {
        delete process.env.BASE_URL;
      } else {
        process.env.BASE_URL = previous;
      }
    });
}

function rawConfig() {
  return {
    baseUrl: "http://localhost:8888",
    productionUrl: "https://developer.konghq.com",
  };
}

const FIXTURES = path.join(import.meta.dirname, "../fixtures/how-tos/event-gateway");

test("with no BASE_URL, the run targets the baseUrl from config/tests.yaml", async () => {
  await withEnv({}, () => {
    const config = resolveDevServerTarget(rawConfig());

    assert.equal(config.baseUrl, "http://localhost:8888");
    assert.equal(config.origin, "http://localhost:8888");
  });
});

test("a set BASE_URL wins over the config's baseUrl", async () => {
  await withEnv({ BASE_URL: "http://localhost:8898" }, () => {
    const config = resolveDevServerTarget(rawConfig());

    assert.equal(config.baseUrl, "http://localhost:8898");
    assert.equal(config.origin, "http://localhost:8898");
  });
});

test("the resolved config keeps the raw config's other keys", async () => {
  await withEnv({}, () => {
    const config = resolveDevServerTarget(rawConfig());

    assert.equal(config.productionUrl, "https://developer.konghq.com");
  });
});

test("a target with a trailing slash resolves without it", async () => {
  await withEnv({ BASE_URL: "http://localhost:8908/" }, () => {
    const config = resolveDevServerTarget(rawConfig());

    assert.equal(config.baseUrl, "http://localhost:8908");
  });
});

test("a value that parses but is not an http(s) URL fails naming the value", async () => {
  await withEnv({ BASE_URL: "localhost:8898" }, () => {
    assert.throws(() => resolveDevServerTarget(rawConfig()), /localhost:8898/);
  });
});

test("a value that is not a URL fails naming the value", async () => {
  await withEnv({ BASE_URL: "not a url" }, () => {
    assert.throws(() => resolveDevServerTarget(rawConfig()), /not a url/);
  });
});

test("visitedOrigins returns the distinct origins of a URL list in a stable order", () => {
  assert.deepEqual(
    visitedOrigins([
      "http://localhost:8898/how-to/first/",
      "http://localhost:8888/how-to/second/",
      "http://localhost:8898/how-to/third/",
    ]),
    ["http://localhost:8898", "http://localhost:8888"],
  );
});

test("visitedOrigins fails naming a malformed URL", () => {
  assert.throws(() => visitedOrigins(["not a url"]), /not a url/);
});

test("the resolved target reaches the URLs the run visits", async () => {
  await withEnv({ BASE_URL: "http://localhost:8908/" }, async () => {
    const config = resolveDevServerTarget(rawConfig());

    const originalCwd = process.cwd();
    const workDir = await fs.mkdtemp(path.join(os.tmpdir(), "dev-server-target-"));
    process.chdir(workDir);
    try {
      const urls = await testeableUrlsFromFiles(config, [
        path.join(FIXTURES, "testable.md"),
        path.join(FIXTURES, "series-first.md"),
      ]);

      assert.deepEqual(urls, [
        "http://localhost:8908/how-to/testable/",
        "http://localhost:8908/how-to/series-first/",
      ]);
    } finally {
      process.chdir(originalCwd);
      await fs.rm(workDir, { recursive: true, force: true });
    }
  });
});
