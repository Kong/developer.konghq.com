import debug from "debug";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const debugLog = debug("debug");
const __dirname = dirname(fileURLToPath(import.meta.url));

export async function fetchImage(docker, imageName, runtime, log) {
  log(`Fetching the image '${imageName}'...`);
  try {
    const image = await docker.getImage(imageName);
    await image.inspect();
    log(`Image '${imageName}' already exists.`);
    return;
  } catch (err) {
    log(`Image '${imageName}' not found, building it...`);

    return new Promise((resolve, reject) => {
      const dockerContext = join(__dirname, "docker", runtime);

      docker.buildImage(
        {
          context: dockerContext,
          src: ["Dockerfile"],
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

export async function executeCommand(container, cmd) {
  return new Promise(async (resolve, reject) => {
    try {
      const execCommand = await container.exec({
        Cmd: ["bash", "-c", cmd],
        AttachStdout: true,
        AttachStderr: true,
      });

      await new Promise((resolve, reject) => {
        execCommand.start({}, (err, stream) => {
          let output = "";
          if (err) {
            return reject(err);
          }
          stream.on("data", (chunk) => {
            output += chunk.toString();
          });
          stream.on("end", function () {
            debugLog(output);
            return resolve(output);
          });
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
