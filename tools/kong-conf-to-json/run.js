import fs from "fs";
import minimist from "minimist";

function parseConfigFile(filePath, sections) {
  const config = {};
  const lines = fs.readFileSync(filePath, "utf-8").split("\n");

  let currentParam = null;
  let inDescription = false;

  lines.forEach((line, index) => {
    // Check if the line starts a new parameter definition
    const paramMatch = line.match(/^\#(\w+)\s\=/);
    if (paramMatch) {
      currentParam = paramMatch[1]; // Remove the leading "#"
      const sectionIndex = sections.findIndex((section) => {
        return section.start <= index && index <= section.end;
      });

      config[currentParam] = {
        defaultValue: null,
        description: "",
        sectionIndex,
      };
      inDescription = false;
    }

    // Check if the line contains a default value assignment
    const defaultValueMatch = line.match(/^\#\w+\s\=(\s[^#\n]*)(\#.*|$)/);
    if (defaultValueMatch) {
      const value = defaultValueMatch[1].trimStart();
      if (value === "") {
        config[currentParam].defaultValue = null;
      } else {
        if (value.split(",").length > 1) {
          config[currentParam].defaultValue = value
            .split(",")
            .map((v) => v.trim());
        } else {
          config[currentParam].defaultValue = value.trimEnd();
        }
      }
    }

    let descriptionMatch;
    if (!inDescription) {
      if (paramMatch) {
        descriptionMatch = line.match(/^\#\w+\s\=\s[^#\n]*(\#.*)/);
        if (descriptionMatch) {
          config[currentParam].description += descriptionMatch[1]
            .trim()
            .slice(1)
            .trimStart() // Remove initial "#" and leading spaces
            .concat("\n");
        }
        inDescription = true;
      } else {
      }
    } else {
      descriptionMatch = line.match(/^\s+\#(.*)/);
      if (descriptionMatch) {
        config[currentParam].description += line.trim().slice(2).concat("\n"); // Remove initial "# "
      } else {
        inDescription = false;
      }
    }
  });

  return config;
}

function parseSections(filePath) {
  const content = fs.readFileSync(filePath, "utf8");
  const lines = content.split("\n");

  const regex = /#-{78,79}\n# (.*?)\n#\s?-{78,79}\n\n?((#\s.*\n|#\n)*)\n*?#\w/g;

  const sections = [];
  let match;
  while ((match = regex.exec(content)) !== null) {
    const title = match[1].trim();
    const matchStart = content.lastIndexOf(
      match[0],
      regex.lastIndex - match[0].length
    );
    const start = content.slice(0, matchStart).split("\n").length;
    if (sections.length > 0) {
      sections[sections.length - 1].end = start - 1;
    }
    const descriptionString = match[2];
    let description = "";
    if (descriptionString) {
      description = descriptionString
        .split("\n")
        .map((line) => line.slice(1).trim())
        .join("\n");
    }
    sections.push({ title, start, end: null, description });
  }
  sections[sections.length - 1].end = lines.length;

  return sections;
}

(function main() {
  const args = minimist(process.argv.slice(2));

  try {
    if (!args.file) {
      console.error(
        "Missing argument --file, relative path to the kong.conf file."
      );
      process.exit(1);
    }

    if (!args.version) {
      console.error(
        "Missing argument --version, version of the kong.conf file to parse."
      );
      process.exit(1);
    }

    const configFilePath = args.file;
    const version = args.version;
    const sections = parseSections(configFilePath);
    const jsonConfig = parseConfigFile(configFilePath, sections);
    const destinationPath = `../../app/_data/kong-conf/${version}.json`;

    fs.writeFileSync(
      destinationPath,
      JSON.stringify(jsonConfig, null, 2),
      "utf8"
    );
    console.log(`kong.conf file in json format written to ${destinationPath}.`);
    return 0;
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
})();
