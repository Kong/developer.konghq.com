import fs from "fs/promises";
import yaml from "js-yaml";

const expectedFailures = yaml.load(
  await fs.readFile("./config/expected_failures.yaml", "utf-8")
);

export function isFailureExpected(result) {
  return expectedFailures[result.file] === result.assertions[0];
}

export function logResult(result) {
  const statusIcons = {
    passed: "✅",
    failed: isFailureExpected(result) ? "🤔" : "❌",
    skipped: "⚠️",
  };
  const icon = statusIcons[result.status] || "❓";

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

function processStatus(result) {
  if (isFailureExpected(result)) {
    return "other";
  } else {
    return result.status;
  }
}

function buildTestList(results) {
  return results.map((result) => ({
    name: result.name,
    message: processAssertions(result.assertions),
    status: processStatus(result),
    duration: result.duration,
  }));
}

export async function logResults(results, start, stop) {
  const skippedInstructions = yaml.load(
    await fs.readFile("./.automated-tests", "utf-8")
  );
  const { passed, failed, skipped } = categorizeResults(
    results.concat(skippedInstructions)
  );
  const { expectedCount, failedCount } = summarizeFailures(failed);

  const resultObject = {
    reportFormat: "CTRF",
    specVersion: "0.0.0",
    results: {
      tool: { name: "automated-tests" },
      summary: buildSummary(
        results,
        passed,
        skipped,
        failedCount,
        expectedCount,
        start,
        stop
      ),
      tests: buildTestList(results),
    },
  };

  console.log(
    `Summary: ${results.length} total. ${passed.length} passed, ${failedCount} failed, ${skipped.length} skipped, expected failures: ${expectedCount}.`
  );

  console.log("Tests result logged to ./testReport.json");

  await fs.writeFile(
    "testReport.json",
    JSON.stringify(resultObject, null, 2),
    "utf-8"
  );
}
