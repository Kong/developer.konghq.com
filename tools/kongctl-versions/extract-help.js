import { exec as execCb } from 'child_process';
import { promisify } from 'util';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const execAsync = promisify(execCb);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

(async () => {
  try {
    const baseOutputDir = path.resolve(__dirname, '../../app/_includes/kongctl/help');
    const docsOutputDir = path.resolve(__dirname, '../../app/kongctl');

    // Keep generated help authoritative by removing stale command includes first.
    fs.rmSync(baseOutputDir, { recursive: true, force: true });
    fs.mkdirSync(baseOutputDir, { recursive: true });

    // Get top-level commands from `kongctl --help`
    const { stdout: topHelp } = await execAsync('kongctl --help');
    const availableCommands = extractCommands(topHelp);

    for (const command of availableCommands) {
      // Fetch and save the command-level help: `kongctl <command> --help`
      const { stdout: cmdHelpStdout } = await execAsync(`kongctl ${command} --help`);
      const cmdHelp = extractCommandSpecificHelp(cmdHelpStdout);

      // Create directory for this command and write command-level help to index.md
      const commandDir = path.join(baseOutputDir, command);
      if (!fs.existsSync(commandDir)) {
        fs.mkdirSync(commandDir, { recursive: true });
      }

      const commandIndexPath = path.join(commandDir, 'index.md');
      fs.writeFileSync(commandIndexPath, "```ansi\n" + cmdHelp + "\n```", 'utf8');
      console.log(`Wrote help for 'kongctl ${command} --help' to ${command}/index.md`);

      // Extract second-level subcommands (e.g. `api` in `kongctl get api`)
      const subCommands = extractCommands(cmdHelpStdout);

      // commandDir already created above
      for (const subCommand of subCommands) {
        // Fetch subcommand-level help
        const { stdout: subCmdHelpStdout } = await execAsync(`kongctl ${command} ${subCommand} --help`);
        const subCmdHelp = extractCommandSpecificHelp(subCmdHelpStdout);

        // Check if this subcommand has its own subcommands
        const subSubCommands = extractCommands(subCmdHelpStdout);
        if (subSubCommands.length > 0) {
          // Create folder for the subcommand and write its index.md
          const nestedDir = path.resolve(commandDir, subCommand);
          if (!fs.existsSync(nestedDir)) {
            fs.mkdirSync(nestedDir, { recursive: true });
          }

          const subIndexPath = path.join(nestedDir, 'index.md');
          fs.writeFileSync(subIndexPath, "```ansi\n" + subCmdHelp + "\n```", 'utf8');
          console.log(`Wrote help for 'kongctl ${command} ${subCommand}' to ${command}/${subCommand}/index.md`);

          // Write sub-subcommand files
          for (const subSubCommand of subSubCommands) {
            try {
              const { stdout: subSubStdout } = await execAsync(`kongctl ${command} ${subCommand} ${subSubCommand} --help`);
              const subSubHelp = extractCommandSpecificHelp(subSubStdout);
              const subSubFilePath = path.join(nestedDir, `${subSubCommand}.md`);
              fs.writeFileSync(subSubFilePath, "```ansi\n" + subSubHelp + "\n```", 'utf8');
              console.log(`Wrote help for 'kongctl ${command} ${subCommand} ${subSubCommand}'`);
            } catch (err) {
              console.error(`Failed to get help for 'kongctl ${command} ${subCommand} ${subSubCommand}': ${err.message}`);
            }
          }
        } else {
          // No further children: write subcommand.md directly under commandDir
          const subCommandFilePath = path.join(commandDir, `${subCommand}.md`);
          fs.writeFileSync(subCommandFilePath, "```ansi\n" + subCmdHelp + "\n```", 'utf8');
          console.log(`Wrote help for 'kongctl ${command} ${subCommand}' to ${command}/${subCommand}.md`);
        }
      }
    }

    const removedPages = pruneStaleReferencePages(docsOutputDir, baseOutputDir);
    pruneEmptyDirectories(docsOutputDir);
    console.log(`Removed ${removedPages} stale kongctl docs pages`);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();

function extractCommandSpecificHelp(stdout) {
  const help = [];
  const lines = stdout.split('\n');

  let isInFlags = false;
  for (const line of lines) {
    if (line.startsWith('Global Flags:')) {
      break;
    }

    if (line.startsWith("Usage:")) {
      isInFlags = true;
    }

    if (isInFlags) {
      help.push(line);
    }
  }

  return help.join("\n");
}

function extractCommands(stdout) {
  const availableCommands = [];
  const lines = stdout.split('\n');
  let inCommandsSection = false;

  for (const line of lines) {
    if (line.startsWith('Available Commands:')) {
      inCommandsSection = true;
      continue;
    }

    if (inCommandsSection) {
      if (line.trim() === '' || line.startsWith('Flags:')) {
        break;
      }

      if (!line.includes('[deprecated]')) {
        const command = line.trim().split(/\s+/)[0];
        if (['help', 'completion', 'version'].includes(command)) {
          continue;
        }
        availableCommands.push(command);
      }
    }
  }

  return availableCommands;
}

function pruneStaleReferencePages(docsOutputDir, includesOutputDir) {
  let removedPages = 0;
  const docs = listFilesRecursive(docsOutputDir).filter((filePath) => filePath.endsWith('.md'));

  for (const docPath of docs) {
    const content = fs.readFileSync(docPath, 'utf8');
    const includeMatches = [...content.matchAll(/{%\s*include_cached\s+\/kongctl\/help\/([^\s%]+)\s*%}/g)];

    if (includeMatches.length === 0) {
      continue;
    }

    const hasMissingInclude = includeMatches.some((match) => {
      const includePath = path.resolve(includesOutputDir, match[1]);
      return !fs.existsSync(includePath);
    });

    if (hasMissingInclude) {
      fs.unlinkSync(docPath);
      removedPages += 1;
      const relativePath = path.relative(path.resolve(__dirname, '../../'), docPath);
      console.log(`Removed stale page: ${relativePath}`);
    }
  }

  return removedPages;
}

function listFilesRecursive(rootDir) {
  const entries = fs.readdirSync(rootDir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(rootDir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listFilesRecursive(entryPath));
    } else if (entry.isFile()) {
      files.push(entryPath);
    }
  }

  return files;
}

function pruneEmptyDirectories(rootDir, currentDir = rootDir) {
  const entries = fs.readdirSync(currentDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue;
    }
    pruneEmptyDirectories(rootDir, path.join(currentDir, entry.name));
  }

  if (currentDir === rootDir) {
    return;
  }

  if (fs.readdirSync(currentDir).length === 0) {
    fs.rmdirSync(currentDir);
  }
}
