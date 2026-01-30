const fs = require("fs").promises;
const fg = require("fast-glob");
const matter = require("gray-matter");
const path = require("path");
const YAML = require("yaml");

const Ajv = require("ajv");
const addFormats = require("ajv-formats");

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);

async function validateFrontmatters() {
  const schemas = await fg("../../app/_data/schemas/frontmatter/*.json");
  for (const schemaFile of schemas) {
    const schema = require(schemaFile);
    ajv.addSchema(schema);
  }

  // Ignore plugins pages for now.
  const files = await fg(
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
    }
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

if (require.main === module) {
  try {
    validateFrontmatters();
  } catch (e) {
    console.log(e);
  }
}

module.exports = validateFrontmatters;
