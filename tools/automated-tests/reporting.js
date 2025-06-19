import fs from "fs/promises";
import yaml from "js-yaml";

const expectedFailures = yaml.load(
  await fs.readFile("./config/expected_failures.yaml", "utf-8")
);

function isFailureExpected(result) {
  const expectedFailure = expectedFailures[result.file];
  return expectedFailure && expectedFailure === result.assertions[0];
}

export function logResult(result) {
  process.stdout.write(`Test: ${result.file} `);
  switch (result.status) {
    case "passed":
      process.stdout.write("✅");
      break;
    case "failed":
      if (isFailureExpected(result)) {
        process.stdout.write("🤔");
      } else {
        process.stdout.write("❌");
      }
      break;
    case "skipped":
      process.stdout.write("⚠️");
      break;
    default:
      process.stdout.write("❓");
  }
  console.log();
}

export async function logResults(results) {
  const passed = results.filter((r) => r.status === "passed");
  const failed = results.filter((r) => r.status === "failed");
  const skipped = results.filter((r) => r.status === "skipped");

  let expectedCount = 0;
  let failedCount = 0;

  console.log();

  if (failed.length > 0) {
    for (const failure of failed) {
      if (isFailureExpected(failure)) {
        expectedCount++;
        continue;
      }
      failedCount++;

      console.error(`Test: ${failure.file} failed.`);
      console.error(failure.assertions);
    }
  }

  console.log(
    `Summary: ${results.length} total. ${passed.length} passed, ${failedCount} failed, ${skipped.length} skipped, expected failures: ${expectedCount}.`
  );

  console.log("Tests result logged to ./testReport.json");
  await fs.writeFile(
    "testReport.json",
    JSON.stringify(results, null, 2),
    "utf-8"
  );
}
