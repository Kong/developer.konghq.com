import { exec as execCb } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';
import { writeHelpTree, pruneStalePages } from '../lib/tool-versions.js';

const execAsync = promisify(execCb);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function extractCommands(stdout) {
  const commands = [];
  const lines = stdout.split('\n');
  let inCommandsSection = false;

  for (const line of lines) {
    if (line.startsWith('Commands:')) {
      inCommandsSection = true;
      continue;
    }

    if (inCommandsSection) {
      if (line.trim() === '') {
        break;
      }

      const command = line.trim().split(/\s+/)[0];
      if (['help', 'completion', 'version'].includes(command)) {
        continue;
      }
      commands.push(command);
    }
  }

  return commands;
}

export async function buildCommandTree({ exec = execAsync } = {}) {
  const { stdout: topHelp } = await exec('agent-auth-cli --help');
  const tree = [];

  for (const command of extractCommands(topHelp)) {
    const { stdout: help } = await exec(`agent-auth-cli ${command} --help`);
    const node = { name: command, help: help.trimEnd() };

    const subcommands = extractCommands(help);
    if (subcommands.length > 0) {
      node.subcommands = [];
      for (const subcommand of subcommands) {
        const { stdout: subHelp } = await exec(`agent-auth-cli ${command} ${subcommand} --help`);
        node.subcommands.push({ name: subcommand, help: subHelp.trimEnd() });
      }
    }

    tree.push(node);
  }

  return tree;
}

async function main() {
  const includesDir = path.resolve(__dirname, '../../app/_includes/agent-auth-cli/help');
  const docsDir = path.resolve(__dirname, '../../app/agent-auth-cli');

  const tree = await buildCommandTree();
  writeHelpTree({ tree, includesDir, fence: '```' });

  const removedPages = pruneStalePages({
    docsDir,
    includesDir,
    includePattern: /{%\s*include_cached\s+agent-auth-cli\/help\/([^\s%]+)\s*%}/g,
  });
  console.log(`Removed ${removedPages} stale agent-auth-cli docs pages`);
}

const isEntry = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isEntry) {
  main().catch((error) => {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  });
}
