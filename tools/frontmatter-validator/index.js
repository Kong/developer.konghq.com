import fs from "fs/promises";
import { readFileSync } from "fs";
import { glob } from "tinyglobby";
import matter from "gray-matter";
import path from "path";
import YAML from "yaml";
import { fileURLToPath } from "url";

import Ajv from "ajv";
import addFormats from "ajv-formats";

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

async function validateFrontmatters() {
  const schemas = await glob("../../app/_data/schemas/frontmatter/*.json");
  for (const schemaFile of schemas) {
    const schema = JSON.parse(readFileSync(schemaFile, "utf-8"));
    ajv.addSchema(schema);
  }

  // Ignore plugins pages for now.
  const files = await glob(
    ["app/**/*.md", "app/_landing_pages/**/*.{yaml,yml}"],
    {
      ignore: [
        "app/_layouts/**",
        "app/_includes/**",
        "app/_kong_plugins/**/changelog.md",
        "app/_kong_plugins/**/reference.md",
        "app/_api/**/*.md",
        "app/_references/**/*.md",
        "app/assets/**",
        "app/mesh/latest_version.md",
      ],
      cwd: "../../",
    },
  );

  const errors = [];
  for (const filePath of files) {
    let data;
    const file = await fs.readFile(`../../${filePath}`, "utf-8");
    if (path.extname(filePath) == ".md") {
      data = matter(file).data;
    } else {
      data = YAML.parse(file)["metadata"];
    }

    // look for specific schema
    let validate = ajv.getSchema(`schema:${data.content_type}`);
    if (!validate) {
      validate = ajv.getSchema("schema:base");
    }

    const valid = validate(data);
    if (!valid) {
      errors.push({ filePath: filePath, errors: validate.errors });
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

  console.log("No invalid frontmatters detected.");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    validateFrontmatters();
  } catch (e) {
    console.log(e);
  }
}

export default validateFrontmatters;
