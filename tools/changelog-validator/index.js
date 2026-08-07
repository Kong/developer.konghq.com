import fs from "fs/promises";
import { readFileSync } from "fs";
import { glob } from "tinyglobby";
import yaml from "js-yaml";
import { fileURLToPath } from "url";

import Ajv from "ajv";
import addFormats from "ajv-formats";

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

async function validateChangelogs() {
  const schema = JSON.parse(
    readFileSync("../../app/_data/schemas/changelog/konnect.json", "utf-8"),
  );
  const validate = ajv.compile(schema);

  const files = await glob(["app/_data/changelogs/konnect/*.{yml,yaml}"], {
    cwd: "../../",
  });

  const errors = [];
  for (const filePath of files) {
    const file = await fs.readFile(`../../${filePath}`, "utf-8");
    const data = yaml.load(file);

    // js-yaml parses unquoted ISO dates (e.g. `date: 2026-07-31`) into a
    // native Date, but the schema validates the YAML source as a string.
    if (data && data.date instanceof Date) {
      data.date = data.date.toISOString().slice(0, 10);
    }

    if (!validate(data)) {
      errors.push({ filePath, errors: validate.errors });
    }
  }

  if (errors.length) {
    console.log(`Errors: ${errors.length}`);
    for (const error of errors) {
      console.log(error.filePath);
      console.log(JSON.stringify(error.errors, null, 2));
    }
    process.exit(1);
  }

  console.log(`No invalid changelog entries detected (${files.length} checked).`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    validateChangelogs();
  } catch (e) {
    console.log(e);
    process.exit(1);
  }
}

export default validateChangelogs;
