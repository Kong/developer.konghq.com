import fs from "fs";
import path from "path";

export function runSchemaPostProcessor({
  absoluteSchemasPath,
  outputDir,
  processSchema,
}) {
  if (!fs.existsSync(absoluteSchemasPath)) {
    throw new Error(`Schemas directory not found: ${absoluteSchemasPath}`);
  }

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`Created output directory: ${outputDir}`);
  }

  const files = fs.readdirSync(absoluteSchemasPath);
  const jsonFiles = files.filter((file) => file.endsWith(".json"));

  if (jsonFiles.length === 0) {
    console.log("No JSON files found in the schemas directory.");
    return { hadErrors: false };
  }

  console.log(`Processing ${jsonFiles.length} JSON schema files...`);

  let hadErrors = false;

  for (const file of jsonFiles) {
    try {
      const inputFilePath = path.join(absoluteSchemasPath, file);
      const outputFilePath = path.join(outputDir, file);

      console.log(`Processing: ${file}`);

      const schemaContent = fs.readFileSync(inputFilePath, "utf8");
      const schema = JSON.parse(schemaContent);

      const processedSchema = processSchema(schema);

      fs.writeFileSync(
        outputFilePath,
        JSON.stringify(processedSchema, null, 2),
      );

      console.log(`Processed and saved: ${file} ✓`);
    } catch (error) {
      console.error(`Error processing file ${file}:`, error.message);
      hadErrors = true;
    }
  }

  console.log(`\nCompleted processing. Output saved to: ${outputDir}`);

  return { hadErrors };
}
