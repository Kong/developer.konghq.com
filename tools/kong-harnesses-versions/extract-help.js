import { exec as execCb } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import { writeHelpTree, pruneStalePages, extractCobraCommands } from '../lib/tool-versions.js';

const execAsync = promisify(execCb);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function buildCommandTree({ exec = execAsync } = {}) {
  const { stdout: topHelp } = await exec('kong-harnesses --help');
  const tree = [];

  for (const command of extractCobraCommands(topHelp)) {
    const { stdout: help } = await exec(`kong-harnesses ${command} --help`);
    const node = { name: command, help: help.trimEnd() };

    const subcommands = extractCobraCommands(help);
    if (subcommands.length > 0) {
      node.subcommands = [];
      for (const subcommand of subcommands) {
        const { stdout: subHelp } = await exec(`kong-harnesses ${command} ${subcommand} --help`);
        node.subcommands.push({ name: subcommand, help: subHelp.trimEnd() });
      }
    }

    tree.push(node);
  }

  return tree;
}

async function main() {
  const includesDir = path.resolve(__dirname, '../../app/_includes/kong-harnesses/help');
  const docsDir = path.resolve(__dirname, '../../app/kong-harnesses');

  const tree = await buildCommandTree();
  writeHelpTree({ tree, includesDir, fence: '```' });

  const removedPages = pruneStalePages({
    docsDir,
    includesDir,
    includePattern: /{%\s*include_cached\s+kong-harnesses\/help\/([^\s%]+)\s*%}/g,
  });
  console.log(`Removed ${removedPages} stale kong-harnesses docs pages`);
}

const isEntry = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isEntry) {
  main().catch((error) => {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  });
}
