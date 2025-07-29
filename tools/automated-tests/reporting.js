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
  failedCount,
  expectedCount,
  start,
  stop
) {
  return {
    tests: results.length,
    passed: passed.length,
    failed: failedCount,
    pending: 0,
    skipped: 0,
    other: expectedCount,
    suites: 1,
    start,
    stop,
  };
}

function processAssertions(assertions) {
  return assertions
    .map((a) => {
      try {
        const json = JSON.parse(a);
        return JSON.stringify(json, null, 2);
      } catch (error) {
        return a;
      }
    })
    .join("\n");
}

function buildTestList(results) {
  return results.map(({ file, status, duration, assertions }) => ({
    name: file,
    message: processAssertions(assertions),
    status,
    duration,
  }));
}

export async function logResults(results, start, stop) {
  const { passed, failed, skipped } = categorizeResults(results);
  const { expectedCount, failedCount } = summarizeFailures(failed);

  const resultObject = {
    reportFormat: "CTRF",
    specVersion: "0.0.0",
    results: {
      tool: { name: "automated-tests" },
      summary: buildSummary(
        results,
        passed,
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
