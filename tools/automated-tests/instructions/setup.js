import fs from "fs/promises";
import yaml from "js-yaml";

// TODO: handle this when running one file at a time
export async function processSetup(setup) {
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
  return setupConfig;
}

export async function getSetupConfig(instructions) {
  const setup = instructions["setup"][0];
  const config = await processSetup(setup);
  return config;
}
