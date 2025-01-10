import fs from "fs/promises";
import yaml from "js-yaml";

async function processSetup(setup) {
  let product;
  let version;
  let image;
  if (typeof setup === "object") {
    // It should be one key/value pair, e.g. { gateway: 'x.y' }
    product = Object.keys(setup)[0];
    version = setup[product];
  } else {
    // Not an object, for products/platforms that don't have versions.
    product = setup;
  }
  image = `automated-tests:${product}`;

  const fileContent = await fs.readFile(`./config/setup.yaml`, "utf8");
  const setupConfigs = yaml.load(fileContent);

  const productConfig = setupConfigs[product];

  if (!productConfig) {
    throw new Error(`Missing config for: '${product}' in config/setup.yaml`);
  }

  let setupConfig = {
    image,
    product,
    commands: productConfig["commands"],
  };

  if (version && productConfig["versions"]) {
    // TODO: overwrite the version with an env variable
    const versionConfig = productConfig["versions"].find(
      (v) => v["version"] == version
    );

    if (!versionConfig) {
      throw new Error(
        `Missing version config for version: '${version}' in ${product}`
      );
    }

    let env = versionConfig["env"];
    // Add gateway license
    env["KONG_LICENSE_DATA"] = process.env.KONG_LICENSE_DATA;

    setupConfig["env"] = Object.entries(env).map(
      ([key, value]) => `${key}=${value}`
    );
  }
  return setupConfig;
}

export async function getSetupConfig(instructions) {
  const setup = instructions["setup"][0];
  const config = await processSetup(setup);
  return config;
}
