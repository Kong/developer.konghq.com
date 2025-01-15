import debug from "debug";
import fs from "fs/promises";
import yaml from "js-yaml";
import { executeCommand, fetchImage } from "./docker-helper.js";

const log = debug("tests:setup:runtime");

export async function getRuntimeConfig(runtime) {
  const fileContent = await fs.readFile(`./config/runtimes.yaml`, "utf8");
  const configs = yaml.load(fileContent);
  const imageName = `automated-tests:${runtime}`;

  if (configs[runtime]) {
    return { ...configs[runtime], runtime, imageName };
  } else {
    throw new Error(`Unsupported runtime: ${runtime}`);
  }
}

export async function runtimeEnvironment(testsConfig, runtimeConfig) {
  const version = testsConfig[runtimeConfig.runtime];
  let environment = [];

  if (version) {
    // TODO: overwrite the version with an env variable
    const versionConfig = runtimeConfig["versions"].find(
      (v) => v["version"] == version
    );

    if (!versionConfig) {
      throw new Error(
        `Missing version config for version: '${version}' in ${runtimeConfig.runtime}`
      );
    }

    let env = versionConfig["env"];
    // Add gateway license
    env["KONG_LICENSE_DATA"] = process.env.KONG_LICENSE_DATA;

    environment = Object.entries(env).map(([key, value]) => `${key}=${value}`);
  }
  return environment;
}

export async function setupRuntime(testsConfig, runtimeConfig, docker) {
  await fetchImage(docker, runtimeConfig.imageName, runtimeConfig.runtime, log);
  const env = await runtimeEnvironment(testsConfig, runtimeConfig);

  // TODO: extract env from runtimeConfig + testsConfig
  const container = await docker.createContainer({
    Image: runtimeConfig.imageName,
    Tty: true,
    ENV: env,
    HostConfig: {
      Binds: ["/var/run/docker.sock:/var/run/docker.sock"],
      NetworkMode: "host",
    },
  });

  await container.start();

  log("Setting things up...");
  if (runtimeConfig.setup.commands) {
    for (const command of runtimeConfig.setup.commands) {
      await executeCommand(container, command);
    }
  }

  return container;
}

export async function cleanupRuntime(runtimeConfig, container) {
  log("Cleaning up...");
  if (runtimeConfig.cleanup.commands) {
    for (const command of runtimeConfig.cleanup.commands) {
      await executeCommand(container, command);
    }
  }
}

export async function resetRuntime(runtimeConfig, container) {
  log("Resetting...");
  if (runtimeConfig.reset.commands) {
    for (const command of runtimeConfig.reset.commands) {
      await executeCommand(container, command);
    }
  }
}
