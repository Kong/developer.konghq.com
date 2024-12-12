import minimist from "minimist";
import { promises as fs, existsSync } from "fs";
import path from "path";

const argv = minimist(process.argv.slice(2));
const __dirname = path.dirname(new URL(import.meta.url).pathname);

(async function () {
  const pluginName = argv._[0];
  const toolDir = path.resolve(__dirname);
  const rootDir = path.resolve(toolDir, "../../");
  const templatesFolder = path.resolve(toolDir, "./templates");

  if (!pluginName) {
    console.error("Please provide the name of the plugin.");
    process.exit(1);
  }

  const pluginFolder = path.resolve(rootDir, `app/_kong_plugins/${pluginName}`);

  try {
    console.log(`Scaffolding plugin: ${pluginName}...`);

    if (!existsSync(pluginFolder)) {
      await fs.mkdir(pluginFolder);
    }
    console.log(`Plugin folder created at: ${pluginFolder}`);

    const items = await fs.readdir(templatesFolder, { withFileTypes: true });

    console.log("Copying templates...");
    for (const item of items) {
      if (item.isDirectory()) {
        if (!existsSync(path.join(pluginFolder, item.name))) {
          await fs.mkdir(path.join(pluginFolder, item.name));
        }
        const subFolder = path.join(templatesFolder, item.name);
        const files = await fs.readdir(subFolder);

        for (const file of files) {
          if (existsSync(path.join(pluginFolder, item.name, file))) {
            continue;
          }
          await fs.copyFile(
            path.join(subFolder, file),
            path.join(pluginFolder, item.name, file)
          );
        }
      } else {
        if (existsSync(path.join(pluginFolder, item.name))) {
          continue;
        }
        await fs.copyFile(
          path.join(templatesFolder, item.name),
          path.join(pluginFolder, item.name)
        );
      }
      console.log(`  * ${item.name}`);
    }
    console.log("Done!");
  } catch (error) {
    console.error("Error creating the plugin folder or files:", error);
    process.exit(1);
  }
})();
