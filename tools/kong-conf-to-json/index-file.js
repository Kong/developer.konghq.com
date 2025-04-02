import fs from "fs";
import fg from "fast-glob";

function mergeSections(obj1, obj2) {
  const normalizeTitle = (title) =>
    title === "WEBASSEMBLY (WASM)" ? "WASM" : title;

  const mergedMap = new Map();

  obj1.forEach((section) => {
    mergedMap.set(normalizeTitle(section.title), section);
  });

  obj2.forEach((section) => {
    mergedMap.set(normalizeTitle(section.title), section);
  });

  return Array.from(mergedMap.values());
}

function generateIndexFile() {
  let reference = {};
  let previousVersion;
  let files = fg.sync("../../app/_data/kong-conf/*", {
    ignore: ["../../app/_data/kong-conf/index.json"],
  });

  files = files.sort((a, b) => {
    const versionA = a
      .match(/(\d+\.\d+)/)[0]
      .split(".")
      .map(Number);
    const versionB = b
      .match(/(\d+\.\d+)/)[0]
      .split(".")
      .map(Number);
    return versionA[0] - versionB[0] || versionA[1] - versionB[1];
  });

  files.forEach((file, index) => {
    const newConf = fs.readFileSync(file, "utf-8");
    const newConfJson = JSON.parse(newConf);
    const match = file.match(/(\d+\.\d+)\.json/);

    if (!match) {
      console.error(
        `Could not extract the version from the file path: ${file}`
      );
      process.exit(1);
    }
    const version = match[1];

    if (index === 0) {
      reference = newConfJson;
      previousVersion = version;
    } else {
      const currentParams = new Set(Object.keys(reference.params));
      const newParams = new Set(Object.keys(newConfJson.params));

      const onlyInCurrentParams = [...currentParams].filter(
        (key) => !newParams.has(key)
      );
      const onlyInNewParams = [...newParams].filter(
        (key) => !currentParams.has(key)
      );
      const intersection = [...currentParams].filter((key) =>
        newParams.has(key)
      );

      // everything that is in next that IS NOT in prev => min: next
      onlyInNewParams.forEach((param) => {
        reference.params[param] = {
          ...newConfJson.params[param],
          min_version: { gateway: version },
        };
      });

      // everything that is in prev that IS NOT in next => max: prev
      onlyInCurrentParams.forEach((param) => {
        reference.params[param] = {
          ...reference.params[param],
        };

        // portal and vitals are still valid even though they were removed
        if (!/portal|vitals_?.*/.test(param)) {
          if (reference.params[param]["removed_in"] === undefined) {
            reference.params[param]["removed_in"] = { gateway: version };
          }
        }
      });
      // everything that is in prev AND next goes in
      intersection.forEach((param) => {
        reference.params[param] = { ...newConfJson.params[param] };
      });

      // copy sections
      reference.sections = mergeSections(
        reference.sections,
        newConfJson.sections
      );
      previousVersion = version;
    }
  });
  return reference;
}

(function main() {
  const indexFile = generateIndexFile();
  const destinationPath = "../../app/_data/kong-conf/index.json";

  fs.writeFileSync(destinationPath, JSON.stringify(indexFile, null, 2), "utf8");
  console.log(
    `Index kong.conf file in json format written to ${destinationPath}.`
  );
})();
