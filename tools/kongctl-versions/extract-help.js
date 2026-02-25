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
    const { stdout } = await execAsync('kongctl --help');

    const availableCommands = extractCommands(stdout);

    for (const command of availableCommands) {
      const { stdout } = await execAsync(`kongctl ${command} --help`);
      const subCommands = extractCommands(stdout);
      for (const subCommand of subCommands) {
        const { stdout } = await execAsync(`kongctl ${command} ${subCommand} --help`);

        const outputDir = path.resolve(__dirname, '../../app/_includes/kongctl/help', command);
        if (!fs.existsSync(outputDir)) {
          fs.mkdirSync(outputDir, { recursive: true });
        }

        const help = extractCommandSpecificHelp(stdout);
        const content = "```bash\n" + help + "\n```";

        const filePath = path.join(outputDir, `${subCommand}.md`);
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Wrote help for 'kongctl ${command} ${subCommand}'`);
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