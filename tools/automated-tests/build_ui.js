import { fileURLToPath } from 'url';
import * as fs from "fs";
import * as path from "path";
import yaml from "js-yaml";

// Output builder
const output = [];


const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const instructions = yaml.load(fs.readFileSync(path.join(__dirname, 'demo-instructions.yaml'), 'utf8')).steps;

for (const instruction of instructions) {
  const match = instruction.match(/Navigate to (https?:\/\/[^\s]+)/);
  if (match) {
    const navUrl = new URL(match[1]);
    output.push({
      navigate: navUrl.pathname,
    });
    continue;
  }

  const urlLabelMatch = instruction.match(/'([^']+)'/);
  const urlValueMatch = instruction.match(/with (https?:\/\/[^\s]+)/);
  if (urlLabelMatch && urlValueMatch) {
    output.push({
      element: 'label',
      label: urlLabelMatch[1],
      fill: urlValueMatch[1],
    });
    continue;
  }

  const labelMatch = instruction.match(/'([^']+)'/);
  const valueMatch = instruction.match(/with `(.*)`/);
  if (labelMatch && valueMatch) {
    output.push({
      element: 'label',
      label: labelMatch[1],
      fill: valueMatch[1],
    });
    continue;
  }

  const clickMatch = instruction.match(/Click on '(.+)'/);
  if (clickMatch) {
    output.push({
      element: 'label',
      text: clickMatch[1],
      action: 'click',
    });
  }

  const buttonMatch = instruction.match(/Click on the (.+) button/);
  if (buttonMatch) {
    output.push({
      element: 'button',
      text: buttonMatch[1],
      action: 'click',
    });
  }
}

console.log(yaml.dump({ steps: output }));