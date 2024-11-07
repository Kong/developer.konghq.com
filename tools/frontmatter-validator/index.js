const fs = require("fs").promises;
const fg = require("fast-glob");
const matter = require("gray-matter");

const Ajv = require("ajv");
const addFormats = require("ajv-formats");

const ajv = new Ajv({ allErrors: true });
addFormats(ajv);

async function validateFrontmatters() {
  const schemas = await fg("../../app/_data/schemas/frontmatter/*.json");
  for (const schemaFile of schemas) {
    const schema = require(schemaFile);
    ajv.addSchema(schema);
  }

  // Ignore plugins pages for now.
  // TODO: landing pages.
  const files = await fg("app/**/*.md", {
    ignore: ["app/_includes/**", "app/_kong_plugins"],
    cwd: "../../",
  });

  const errors = [];
  for (const path of files) {
    const markdown = await fs.readFile(`../../${path}`);
    const { data } = matter(markdown);

    // look for specific schema
    let validate = ajv.getSchema(`schema:${data.content_type}`);
    if (!validate) {
      validate = ajv.getSchema("schema:base");
    }

    const valid = validate(data);
    if (!valid) {
      errors.push({ filePath: path, errors: validate.errors });
    }
  }

  if (errors.length) {
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
