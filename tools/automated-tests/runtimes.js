import debug from "debug";
import fs from "fs/promises";
import yaml from "js-yaml";
import { executeCommand, fetchImage, setEnvVariable } from "./docker-helper.js";
import path from "path";
import { dirname } from "path";
import { fileURLToPath } from "url";

const log = debug("tests:setup:runtime");
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export async function getRuntimeConfig(deploymentModel, product) {
  const fileContent = await fs.readFile(`./config/runtimes.yaml`, "utf8");
  const configs = yaml.load(fileContent);
  const imageName = `automated-tests`;

  if (!configs[deploymentModel]) {
    throw new Error(`Unsupported deployment model: ${deploymentModel}`);
  }

  if (!configs[deploymentModel][product]) {
    throw new Error(
      `Unsupported product '${product}' for deployment model '${deploymentModel}'`
    );
  }

  let config = {
    ...configs[deploymentModel][product],
    deploymentModel,
    product,
    imageName,
  };

  if (config.versions) {
    const versionFromEnv = process.env.GATEWAY_VERSION;
    if (versionFromEnv) {
      config["version"] = versionFromEnv;
    } else {
      throw new Error(`Missing env variable GATEWAY_VERSION`);
    }
  }

  return config;
}

export async function runtimeEnvironment(runtimeConfig) {
  let environment = { ...runtimeConfig.env };
  const version = runtimeConfig.version;

  for (const [key, value] of Object.entries({ ...runtimeConfig.env })) {
    environment[`DECK_${key}`] = value;
  }

  Object.entries(process.env)
    .filter(([key]) => key.startsWith("TESTS"))
    .forEach(([key, value]) => {
      const variable = key.replace("TESTS_", "");

      if (runtimeConfig.deploymentModel !== "konnect" && variable === "KONNECT_TOKEN") {
        return;
      }
      environment[`DECK_${variable}`] = value;
      environment[variable] = value;
    });

  if (version) {
    let versionConfig = runtimeConfig["versions"].find(
      (v) => v["version"] == version
    );

    if (!versionConfig) {
      if (process.env.KONG_IMAGE_NAME && process.env.KONG_IMAGE_TAG) {
        versionConfig = {
          version,
          env: {
            KONG_IMAGE_NAME: process.env.KONG_IMAGE_NAME,
            KONG_IMAGE_TAG: process.env.KONG_IMAGE_TAG,
          },
        };
      } else {
        throw new Error(
          `Missing version config for version: '${version}' in ${runtimeConfig.deploymentModel}/${runtimeConfig.product}`
        );
      }
    }

    environment = { ...environment, ...versionConfig["env"] };
  }

  return environment;
}

export async function setupRuntime(runtimeConfig, docker) {
  const { deploymentModel, product } = runtimeConfig;
  await fetchImage(docker, runtimeConfig.imageName, log);

  const environment = await runtimeEnvironment(runtimeConfig);
  // Add gateway license
  if (!process.env.KONG_LICENSE_DATA) {
    throw new Error("Missing env variable KONG_LICENSE_DATA");
  }
  environment["KONG_LICENSE_DATA"] = process.env.KONG_LICENSE_DATA;

  if (runtimeConfig.version) {
    log(`Setting up ${deploymentModel}/${product} version: ${runtimeConfig.version}...`);
  } else {
    log(`Setting up ${deploymentModel}/${product}...`);
  }
  const env = Object.entries(environment).map(
    ([key, value]) => `${key}=${value}`
  );

  const exportedRealmHostPath = path.resolve(
    __dirname,
    "./config/keycloak-realms"
  );
  const filesHostPath = path.resolve(__dirname, "../../app/_includes/_files");

  const container = await docker.createContainer({
    Image: runtimeConfig.imageName,
    Tty: true,
    ENV: env,
    HostConfig: {
      Binds: [
        "/var/run/docker.sock:/var/run/docker.sock",
        `${exportedRealmHostPath}:/realms`,
        `${filesHostPath}:/files`,
      ],
      NetworkMode: "host",
    },
  });

  await container.start();

  await setEnvVariable(container, "REALM_PATH", exportedRealmHostPath);

  for (const variable of env) {
    const [name, value] = variable.split("=");
    if (name === "KONG_LICENSE_DATA") {
      continue;
    }
    await setEnvVariable(container, name, value);
  }

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

export async function beforeAll(testsConfig, container) {
  log("BeforeAll...");
  if (testsConfig.before?.commands) {
    for (const command of testsConfig.before.commands) {
      await executeCommand(container, command);
    }
  }
}

export async function afterAll(testsConfig, container) {
  log("AfterAll...");
  if (testsConfig.after?.commands) {
    for (const command of testsConfig.after.commands) {
      await executeCommand(container, command);
    }
  }
}
