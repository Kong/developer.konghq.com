import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { load } from "js-yaml";

import {
  testeableUrlsFromFiles,
  selectRunnableGroups,
  isNumericVersion,
  compareVersions,
  effectiveVersionUnderTest,
} from "../instructions-file.js";

const config = {
  baseUrl: "http://localhost:8888",
  productionUrl: "http://localhost:8888",
};

// testeableUrlsFromFiles writes its skipped list to .automated-tests in the
// process cwd. Run each of these tests from a throwaway directory so the
// package's own .automated-tests file survives the suite.
async function inTempDir(fn) {
  const previousCwd = process.cwd();
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "automated-tests-"));
  process.chdir(dir);
  try {
    return await fn(dir);
  } finally {
    process.chdir(previousCwd);
    await fs.rm(dir, { recursive: true, force: true });
  }
}

async function writeHowTo(dir, name, frontmatter, body = "") {
  const file = path.join(dir, name);
  await fs.writeFile(file, `---\n${frontmatter}\n---\n${body}\n`);
  return file;
}

test("an operator how-to with no exclusion is testable", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "operator-dataplane.md",
      ["title: Operator how-to", "products:", "  - operator", "permalink: /operator/how-to/test/"].join(
        "\n",
      ),
    );

    const urls = await testeableUrlsFromFiles(config, [file]);

    assert.deepEqual(urls, ["http://localhost:8888/operator/how-to/test/"]);
  });
});

test("an operator how-to tagged automated_tests=false is skipped", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "operator-skipped.md",
      [
        "title: Skipped operator how-to",
        "products:",
        "  - operator",
        "automated_tests: false",
        "permalink: /operator/how-to/skipped/",
      ].join("\n"),
    );

    const urls = await testeableUrlsFromFiles(config, [file]);

    assert.deepEqual(urls, []);
    const skipped = await fs.readFile(".automated-tests", "utf8");
    assert.match(skipped, /\/operator\/how-to\/skipped\//);
    assert.match(skipped, /operator/);
    assert.match(skipped, /Tagged with automated_tests=false/);
  });
});

function eventGatewayHowTo(name, requiredVersion, extraFrontmatter = []) {
  return [
    `title: ${name}`,
    "products:",
    "  - event-gateway",
    "min_version:",
    `  event-gateway: '${requiredVersion}'`,
    ...extraFrontmatter,
    `permalink: /event-gateway/${name}/`,
  ].join("\n");
}

test("an event-gateway guide requiring a newer version than the one under test is skipped with a min-version reason", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "event-gateway-gated.md",
      eventGatewayHowTo("gated", "1.3"),
    );

    const urls = await testeableUrlsFromFiles(config, [file], {
      imageTag: "1.1",
    });

    assert.deepEqual(urls, []);
    const manifest = load(await fs.readFile(".automated-tests", "utf8"));
    assert.equal(manifest.length, 1);
    assert.match(manifest[0].message, /1\.3/);
    assert.match(manifest[0].message, /1\.1/);
    assert.equal(manifest[0].reason, "min-version");
    assert.deepEqual(manifest[0].products, ["event-gateway"]);
    assert.match(manifest[0].name, /\/event-gateway\/gated\//);
  });
});

test("the version under test is the minimum of the image tag and the control-plane minimum version", async () => {
  await inTempDir(async (dir) => {
    const needs12 = await writeHowTo(
      dir,
      "needs-12.md",
      eventGatewayHowTo("needs-12", "1.2.0"),
    );
    const needs11 = await writeHowTo(
      dir,
      "needs-11.md",
      eventGatewayHowTo("needs-11", "1.1"),
    );

    const urls = await testeableUrlsFromFiles(config, [needs12, needs11], {
      imageTag: "1.3",
      eventGatewayMinVersion: "1.1",
    });

    assert.deepEqual(urls, ["http://localhost:8888/event-gateway/needs-11/"]);
  });
});

test("non-numeric or unset version inputs never gate", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "event-gateway-gated.md",
      eventGatewayHowTo("gated", "1.3"),
    );
    const url = "http://localhost:8888/event-gateway/gated/";

    assert.deepEqual(
      await testeableUrlsFromFiles(config, [file], {
        imageTag: "latest",
        eventGatewayMinVersion: "next",
      }),
      [url],
    );
    assert.deepEqual(
      await testeableUrlsFromFiles(config, [file], { imageTag: "" }),
      [url],
    );
    assert.deepEqual(await testeableUrlsFromFiles(config, [file]), [url]);
  });
});

test("the min-version comparison tolerates mixed segment counts", async () => {
  await inTempDir(async (dir) => {
    const equal = await writeHowTo(
      dir,
      "equal.md",
      eventGatewayHowTo("equal", "1.3.0"),
    );
    assert.deepEqual(
      await testeableUrlsFromFiles(config, [equal], { imageTag: "1.3" }),
      ["http://localhost:8888/event-gateway/equal/"],
    );

    const newer = await writeHowTo(
      dir,
      "newer.md",
      eventGatewayHowTo("newer", "1.3"),
    );
    assert.deepEqual(
      await testeableUrlsFromFiles(config, [newer], { imageTag: "1.1.0" }),
      [],
    );

    const older = await writeHowTo(
      dir,
      "older.md",
      eventGatewayHowTo("older", "1.3"),
    );
    assert.deepEqual(
      await testeableUrlsFromFiles(config, [older], { imageTag: "1.3.1" }),
      ["http://localhost:8888/event-gateway/older/"],
    );
  });
});

test("an event-gateway guide with no min_version runs regardless of the version under test", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "event-gateway-unversioned.md",
      [
        "title: Unversioned how-to",
        "products:",
        "  - event-gateway",
        "permalink: /event-gateway/unversioned/",
      ].join("\n"),
    );

    const urls = await testeableUrlsFromFiles(config, [file], {
      imageTag: "1.1",
    });

    assert.deepEqual(urls, ["http://localhost:8888/event-gateway/unversioned/"]);
  });
});

test("a gateway guide with its own min_version is unaffected by the event-gateway gate", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "gateway-versioned.md",
      [
        "title: Versioned gateway how-to",
        "products:",
        "  - gateway",
        "min_version:",
        "  gateway: '99.9'",
        "permalink: /gateway/versioned/",
      ].join("\n"),
    );

    const urls = await testeableUrlsFromFiles(config, [file], {
      imageTag: "1.1",
      eventGatewayMinVersion: "1.1",
    });

    assert.deepEqual(urls, ["http://localhost:8888/gateway/versioned/"]);
  });
});

test("an explicitly targeted guide with a violated minimum aborts generation", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "event-gateway-gated.md",
      eventGatewayHowTo("gated", "1.3"),
    );

    await assert.rejects(
      testeableUrlsFromFiles(config, [file], {
        explicit: true,
        imageTag: "1.1",
      }),
      (error) => {
        assert.match(error.message, /event-gateway-gated\.md/);
        assert.match(error.message, /1\.3/);
        assert.match(error.message, /1\.1/);
        return true;
      },
    );
  });
});

test("unset version inputs force generation of an explicitly targeted guide", async () => {
  await inTempDir(async (dir) => {
    const file = await writeHowTo(
      dir,
      "event-gateway-gated.md",
      eventGatewayHowTo("gated", "1.3"),
    );

    const urls = await testeableUrlsFromFiles(config, [file], {
      explicit: true,
    });

    assert.deepEqual(urls, ["http://localhost:8888/event-gateway/gated/"]);
  });
});

test("selectRunnableGroups returns only groups matching both filters", () => {
  const groups = {
    "on-prem": { gateway: ["on-prem/gateway.yaml"], operator: ["on-prem/operator.yaml"] },
    konnect: { gateway: ["konnect/gateway.yaml"], operator: ["konnect/operator.yaml"] },
  };

  const selected = selectRunnableGroups(groups, ["operator"], "on-prem");

  assert.deepEqual(selected, {
    "on-prem": { operator: ["on-prem/operator.yaml"] },
  });
});

test("selectRunnableGroups keeps every deployment model when none is set", () => {
  const groups = {
    "on-prem": { gateway: ["on-prem/gateway.yaml"], operator: ["on-prem/operator.yaml"] },
    konnect: { gateway: ["konnect/gateway.yaml"] },
  };

  const selected = selectRunnableGroups(groups, ["gateway"], undefined);

  assert.deepEqual(selected, {
    "on-prem": { gateway: ["on-prem/gateway.yaml"] },
    konnect: { gateway: ["konnect/gateway.yaml"] },
  });
});

test("selectRunnableGroups returns an empty result the caller can detect when nothing matches", () => {
  const groups = {
    konnect: { gateway: ["konnect/gateway.yaml"] },
  };

  const selected = selectRunnableGroups(groups, ["operator"], "on-prem");

  assert.deepEqual(Object.keys(selected), []);
});

test("isNumericVersion accepts a value only when every dotted segment is an integer", () => {
  assert.equal(isNumericVersion("1.3"), true);
  assert.equal(isNumericVersion("1.1.0"), true);
  assert.equal(isNumericVersion("latest"), false);
  assert.equal(isNumericVersion("next"), false);
  assert.equal(isNumericVersion(""), false);
  assert.equal(isNumericVersion(undefined), false);
});

test("compareVersions pads shorter versions with implicit zero segments", () => {
  assert.equal(compareVersions("1.3", "1.3.0"), 0);
  assert.ok(compareVersions("1.3", "1.1.0") > 0);
  assert.ok(compareVersions("1.3", "1.3.1") < 0);
});

test("effectiveVersionUnderTest is the minimum of the numeric version inputs", () => {
  assert.equal(effectiveVersionUnderTest("1.3", "1.1"), "1.1");
  assert.equal(effectiveVersionUnderTest("1.1", "1.3"), "1.1");
  assert.equal(effectiveVersionUnderTest("1.1", "latest"), "1.1");
  assert.equal(effectiveVersionUnderTest("1.1", "next"), "1.1");
  assert.equal(effectiveVersionUnderTest("1.1", undefined), "1.1");
  assert.equal(effectiveVersionUnderTest("latest", "1.1.0"), "1.1.0");
  assert.equal(effectiveVersionUnderTest("", "1.3"), "1.3");
  assert.equal(effectiveVersionUnderTest("latest", "next"), null);
  assert.equal(effectiveVersionUnderTest(undefined, undefined), null);
  assert.equal(effectiveVersionUnderTest("", ""), null);
});
