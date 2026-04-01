import fs from "fs/promises";
import yaml from "js-yaml";

const expectedFailures = yaml.load(
  await fs.readFile("./config/expected_failures.yaml", "utf-8")
);

export function isFailureExpected(result) {
  return expectedFailures[result.file] === result.assertions[0];
}

export function logResult(result) {
  let icon;
  const statusIcons = {
    passed: "✅",
    skipped: "⚠️",
  };
  if (result.status === "failed") {
    icon = isFailureExpected(result) ? "🤔" : "❌";
  } else {
    icon = statusIcons[result.status] || "❓";
  }

  process.stdout.write(`Test: ${result.file} ${icon}\n`);
}

function categorizeResults(results) {
  const categorized = {
    passed: [],
    failed: [],
    skipped: [],
  };

  for (const result of results) {
    if (categorized[result.status]) {
      categorized[result.status].push(result);
    }
  }

  return categorized;
}

function summarizeFailures(failed) {
  let expectedCount = 0;
  let failedCount = 0;

  for (const result of failed) {
    if (isFailureExpected(result)) {
      expectedCount++;
    } else {
      failedCount++;
      console.error(`Test: ${result.file} failed.`);
      console.error(result.assertions);
    }
  }

  return { expectedCount, failedCount };
}

function buildSummary(
  results,
  passed,
  skipped,
  failedCount,
  expectedCount,
  start,
  stop
) {
  return {
    tests: results.length + skipped.length,
    passed: passed.length,
    failed: failedCount,
    pending: 0,
    skipped: skipped.length,
    other: expectedCount,
    suites: 1,
    start,
    stop,
  };
}

function processAssertions(assertions) {
  return assertions
    .map((a) => {
      if (typeof a === "object") {
        return JSON.stringify(a, null, 2);
      } else {
        return a;
      }
    })
    .join("\n");
}

function processMessage(result) {
  if (result.message) {
    return result.message;
  } else {
    return processAssertions(result.assertions);
  }
}

function processStatus(result) {
  if (result.status === "failed" && isFailureExpected(result)) {
    return "other";
  } else {
    return result.status;
  }
}

function buildTestList(results) {
  return results.map((result) => ({
    name: result.name,
    message: processMessage(result),
    status: processStatus(result),
    duration: result.duration,
  }));
}

export async function logResults(results, start, stop, products) {
  const skippedInstructions = yaml.load(
    await fs.readFile("./.automated-tests", "utf-8")
  );

  const filteredSkippedInstructions = skippedInstructions.filter(
    (instruction) =>
      instruction.products &&
      instruction.products.some((product) => products.includes(product))
  );

  const { passed, failed, skipped } = categorizeResults(results);

  const allSkipped = [...skipped, ...filteredSkippedInstructions];

  const { expectedCount, failedCount } = summarizeFailures(failed);

  const resultObject = {
    reportFormat: "CTRF",
    specVersion: "0.0.0",
    results: {
      tool: { name: "automated-tests" },
      summary: buildSummary(
        results,
        passed,
        allSkipped,
        failedCount,
        expectedCount,
        start,
        stop
      ),
      tests: buildTestList(results),
    },
  };

  console.log(
    `Summary: ${results.length + allSkipped.length} total. ${
      passed.length
    } passed, ${failedCount} failed, ${
      allSkipped.length
    } skipped, expected failures: ${expectedCount}.`
  );

  console.log("Tests result logged to ./testReport.json");

  await fs.writeFile(
    "testReport.json",
    JSON.stringify(resultObject, null, 2),
    "utf-8"
  );
}
