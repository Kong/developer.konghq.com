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
    // Get top-level commands from `kongctl --help`
    const { stdout: topHelp } = await execAsync('kongctl --help');
    const availableCommands = extractCommands(topHelp);

    const baseOutputDir = path.resolve(__dirname, '../../app/_includes/kongctl/help');

    for (const command of availableCommands) {
      // Fetch and save the command-level help: `kongctl <command> --help`
      const { stdout: cmdHelpStdout } = await execAsync(`kongctl ${command} --help`);
      const cmdHelp = extractCommandSpecificHelp(cmdHelpStdout);

      if (!fs.existsSync(baseOutputDir)) {
        fs.mkdirSync(baseOutputDir, { recursive: true });
      }

      // Create directory for this command and write command-level help to index.md
      const commandDir = path.join(baseOutputDir, command);
      if (!fs.existsSync(commandDir)) {
        fs.mkdirSync(commandDir, { recursive: true });
      }

      const commandIndexPath = path.join(commandDir, 'index.md');
      fs.writeFileSync(commandIndexPath, "```bash\n" + cmdHelp + "\n```", 'utf8');
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
          fs.writeFileSync(subIndexPath, "```bash\n" + subCmdHelp + "\n```", 'utf8');
          console.log(`Wrote help for 'kongctl ${command} ${subCommand}' to ${command}/${subCommand}/index.md`);

          // Write sub-subcommand files
          for (const subSubCommand of subSubCommands) {
            try {
              const { stdout: subSubStdout } = await execAsync(`kongctl ${command} ${subCommand} ${subSubCommand} --help`);
              const subSubHelp = extractCommandSpecificHelp(subSubStdout);
              const subSubFilePath = path.join(nestedDir, `${subSubCommand}.md`);
              fs.writeFileSync(subSubFilePath, "```bash\n" + subSubHelp + "\n```", 'utf8');
              console.log(`Wrote help for 'kongctl ${command} ${subCommand} ${subSubCommand}'`);
            } catch (err) {
              console.error(`Failed to get help for 'kongctl ${command} ${subCommand} ${subSubCommand}': ${err.message}`);
            }
          }
        } else {
          // No further children: write subcommand.md directly under commandDir
          const subCommandFilePath = path.join(commandDir, `${subCommand}.md`);
          fs.writeFileSync(subCommandFilePath, "```bash\n" + subCmdHelp + "\n```", 'utf8');
          console.log(`Wrote help for 'kongctl ${command} ${subCommand}' to ${command}/${subCommand}.md`);
        }
      }
    }

  } catch (error) {
    console.error(`Error: ${error.message}`);
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