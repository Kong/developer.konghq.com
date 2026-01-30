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
    // kongctl has a flatter command structure than deck
    // Commands like: kongctl login, kongctl get, kongctl plan, etc.
    const commands = [
      'login',
      'logout',
      'get',
      'create',
      'update',
      'delete',
      'plan',
      'apply',
      'sync',
      'diff',
      'dump',
      'adopt',
      'view',
      'api',
      'kai',
      'version'
    ];

    const outputDir = path.resolve(__dirname, '../../app/_includes/kongctl/help');
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    for (const command of commands) {
      try {
        const { stdout } = await execAsync(`kongctl ${command} --help`);
        const help = extractCommandSpecificHelp(stdout);
        const content = "```bash\n" + help + "\n```";

        const filePath = path.join(outputDir, `${command}.md`);
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Wrote help for 'kongctl ${command}'`);
      } catch (error) {
        console.warn(`Warning: Could not extract help for 'kongctl ${command}': ${error.message}`);
      }
    }

  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
})();

function extractCommandSpecificHelp(stdout) {
  const help = [];
  const lines = stdout.split('\n');

  let isInUsage = false;
  for (const line of lines) {
    // Stop at Global Flags section
    if (line.startsWith('Global Flags:')) {
      break;
    }

    // Start capturing from Usage line
    if (line.startsWith("Usage:")) {
      isInUsage = true;
    }

    if (isInUsage) {
      help.push(line);
    }
  }

  return help.join("\n");
}
