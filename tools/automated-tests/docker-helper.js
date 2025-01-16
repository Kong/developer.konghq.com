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

      const result = await new Promise((resolve, reject) => {
        execCommand.start({}, (err, stream) => {
          // Extracted from https://github.com/apocas/dockerode/issues/736
          let buffer = Buffer.alloc(0);
          let output = "";
          if (err) {
            return reject(err);
          }
          stream.on("data", (chunk) => {
            buffer = Buffer.concat([buffer, chunk]);

            while (buffer.length >= 8) {
              // Parse the header
              const header = buffer.slice(0, 8);
              const size = header.readUInt32BE(4); // Last 4 bytes indicate the payload size (big-endian)

              // Check if the full frame is available
              if (buffer.length < 8 + size) {
                break; // Wait for more data if the payload is incomplete
              }

              // Extract the payload
              const payload = buffer.slice(8, 8 + size).toString("utf-8");

              // Append the payload to the appropriate stream
              output += payload;
              // Remove the processed frame from the buffer
              buffer = buffer.slice(8 + size);
            }
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
        const message = `
        Failed to run command ${cmd}
        Got:
        ${result}`;
        reject({ message });
      }
    } catch (error) {
      throw error;
    }
  });
}
