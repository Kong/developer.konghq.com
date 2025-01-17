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
}

export async function logResults(results) {
  const passed = results.filter((r) => r.status === "passed");
  const failed = results.filter((r) => r.status === "failed");
  const skipped = results.filter((r) => r.status === "skipped");

  console.log();

  if (failed.length > 0) {
    for (const failure of failed) {
      if (isFailureExpected(failure)) {
        continue;
      }

      console.log(`Test: ${failure.file} failed.`);
      console.log(failure.assertions);
    }
  }

  console.log(
    `Summary: ${results.length} total. ${passed.length} passed, ${
      failed.length
    } failed, ${skipped.length} skipped, expected failures: ${
      Object.entries(expectedFailures).length || 0
    }.`
  );

  console.log("Tests result logged to ./testReport.json");
  await fs.writeFile(
    "testReport.json",
    JSON.stringify(results, null, 2),
    "utf-8"
  );
}
