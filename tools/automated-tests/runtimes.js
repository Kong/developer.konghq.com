import debug from "debug";
import fs from "fs/promises";
import yaml from "js-yaml";
import { executeCommand, fetchImage } from "./docker-helper.js";

const log = debug("tests:setup:runtime");

export async function getRuntimeConfig(testsConfig, runtime) {
  const fileContent = await fs.readFile(`./config/runtimes.yaml`, "utf8");
  const configs = yaml.load(fileContent);
  const imageName = `automated-tests:${runtime}`;

  if (configs[runtime]) {
    let config = { ...configs[runtime], runtime, imageName };

    // Overwrite the version with an env variable
    const versionFromEnv = process.env[`${runtime.toUpperCase()}_VERSION`];
    if (versionFromEnv) {
      config["version"] = versionFromEnv;
    } else {
      // pull the version from the config file
      const version = testsConfig[runtime];
      if (version) {
        config["version"] = version;
      }
    }

    return config;
  } else {
    throw new Error(`Unsupported runtime: ${runtime}`);
  }
}

export async function runtimeEnvironment(runtimeConfig) {
  let environment = [];
  const version = runtimeConfig.version;

  if (version) {
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

export async function setupRuntime(runtimeConfig, docker) {
  const runtime = runtimeConfig.runtime;
  await fetchImage(docker, runtimeConfig.imageName, runtime, log);
  const env = await runtimeEnvironment(runtimeConfig);

  if (runtimeConfig.version) {
    log(`Setting up ${runtime} version: ${runtimeConfig.version}...`);
  } else {
    log(`Setting up ${runtime}...`);
  }

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
