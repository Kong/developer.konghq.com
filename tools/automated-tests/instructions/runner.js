import Dockerode from "dockerode";
import { join, dirname } from "path";
import { getSetupConfig } from "./setup.js";
import fg from "fast-glob";
import fs from "fs/promises";
import yaml from "js-yaml";
import { fileURLToPath } from "url";
import { processPrereqs } from "./prereqs.js";
import { processCleanup } from "./cleanup.js";
import { processSteps } from "./step.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function executeCommand(container, cmd) {
  return new Promise(async (resolve, reject) => {
    try {
      const execCommand = await container.exec({
        Cmd: ["bash", "-c", cmd],
        AttachStdout: true,
        AttachStderr: true,
      });

      await new Promise((resolve, reject) => {
        execCommand.start({}, (err, stream) => {
          if (err) {
            reject(err);
          }
          stream.pipe(process.stdout);
          stream.on("end", resolve);
        });
      });

      const execInfo = await execCommand.inspect();

      if (execInfo.ExitCode === 0) {
        resolve();
      } else {
        console.error("Command failed with exit code:", execInfo.ExitCode);
        reject(`Failed to run command ${cmd}`);
      }
    } catch (error) {
      throw error;
    }
  });
}

async function stopContainer(container) {
  if (container) {
    await container.stop();
    console.log("Container stopped.");
  }
}

async function removeContainer(container) {
  if (container) {
    await container.remove();
    console.log("Container removed.");
  }
}

async function fetchImage(docker, setupConfig) {
  const imageName = setupConfig.image;
  console.log(`Fetching the image ${imageName}...`);
  try {
    const image = await docker.getImage(imageName);
    await image.inspect();
    console.log(`Image '${imageName}' already exists.`);
    return;
  } catch (err) {
    console.log(`Image '${imageName}' not found, building it...`);

    return new Promise((resolve, reject) => {
      const dockerContext = join(
        __dirname,
        "../",
        "docker",
        setupConfig.product
      );
      // This shuold be just Dockerfile, but for now we need the binary for deck apply
      const srcFiles = fg.sync(["Dockerfile", "./**/*"], {
        cwd: dockerContext,
      });

      docker.buildImage(
        {
          context: dockerContext,
          src: srcFiles,
        },
        { t: imageName },
        function (error, stream) {
          if (error) {
            return reject(error);
          }

          docker.modem.followProgress(stream, onFinished, onProgress);

          function onFinished(err, output) {
            if (err) {
              return reject(err);
            }
            return resolve(output);
          }
          function onProgress(event) {}
        }
      );
    });
  }
}

async function runConfig(config, container) {
  if (config.commands) {
    for (const command of config.commands) {
      await executeCommand(container, command);
    }
  }
}

async function runSetup(config, container) {
  console.log("Setting things up...");
  await runConfig(config, container);
}

async function runPrereqs(prereqs, container) {
  console.log("Running prereqs...");
  if (prereqs) {
    const config = await processPrereqs(prereqs);
    await runConfig(config, container);
  }
}

async function runCleanup(cleanup, container) {
  console.log("Cleaning up...");
  if (cleanup) {
    const config = await processCleanup(cleanup);
    await runConfig(config, container);
  }
}

async function runSteps(steps, container) {
  console.log("Running steps...");
  if (steps) {
    const config = await processSteps(steps);
    await runConfig(config, container);
  }
}

export async function runInstructions(instructions) {
  let container;

  try {
    const setupConfig = await getSetupConfig(instructions);
    const image = setupConfig.image;

    const docker = new Dockerode({
      socketPath: "/var/run/docker.sock",
    });

    await fetchImage(docker, setupConfig);

    container = await docker.createContainer({
      Image: image,
      Tty: true,
      ENV: setupConfig.env,
      HostConfig: {
        Binds: ["/var/run/docker.sock:/var/run/docker.sock"],
        NetworkMode: "host",
      },
    });
    console.log("Container created with ID:", container.id);

    await container.start();
    console.log("Container started.");

    await runSetup(setupConfig, container);

    await runPrereqs(instructions.prereqs, container);

    await runSteps(instructions.steps, container);

    await runCleanup(instructions.cleanup, container);

    await stopContainer(container);

    await removeContainer(container);
  } catch (err) {
    console.error("Error: ", err);
    await stopContainer(container);
    await removeContainer(container);
  }
}

(async function main() {
  const fileContent = await fs.readFile(
    "output/instructions/how-to/add-rate-limiting-for-a-consumer-with-kong-gateway/on-prem.yaml",
    "utf8"
  );
  const instructions = yaml.load(fileContent);
  await runInstructions(instructions);
})();
