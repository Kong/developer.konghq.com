import debug from "debug";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const debugLog = debug("debug");
const __dirname = dirname(fileURLToPath(import.meta.url));

export async function fetchImage(docker, imageName, log) {
  log(`Fetching the image '${imageName}'...`);
  try {
    const image = await docker.getImage(imageName);
    await image.inspect();
    log(`Image '${imageName}' already exists.`);
    return;
  } catch (err) {
    if (err.statusCode !== 404) {
      log(`Unexpected error while fetching image: ${err.message}`);
      throw err;
    }

    log(`Image '${imageName}' not found, building it...`);

    return new Promise((resolve, reject) => {
      const dockerContext = join(__dirname, "docker");

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

          docker.modem.followProgress(
            stream,
            (err, res) => (err ? reject(err) : resolve(res)),
            (event) =>
              event.status
                ? debugLog(event.status.trim())
                : debugLog(event.stream?.trim())
          );
        }
      );
    });
  }
}

export async function executeCommand(container, cmd) {
  return new Promise(async (resolve, reject) => {
    try {
      const execCommand = await container.exec({
        Cmd: [
          "bash",
          "-c",
          `touch /env-vars.sh && source /env-vars.sh && ${cmd}`,
        ],
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
        resolve({ exitCode: execInfo.ExitCode, output: result });
      } else {
        const message = `
        Failed to run command ${cmd}
        Got:
        ${result}`;
        reject({ exitCode: execInfo.ExitCode, output: result, message });
      }
    } catch (error) {
      throw error;
    }
  });
}

export async function stopContainer(container) {
  if (container) {
    await container.stop();
  }
}

export async function removeContainer(container) {
  if (container) {
    await container.remove();
  }
}

export async function setEnvVariable(container, name, value) {
  const writeEnvVar = await container.exec({
    Cmd: [
      "bash",
      "-c",
      `echo 'export ${name}="${value}"' | cat >> /env-vars.sh`,
    ],
    AttachStdout: true,
    AttachStderr: true,
  });

  await new Promise((resolve, reject) => {
    writeEnvVar.start((err, stream) => {
      if (err) return reject(err);

      container.modem.demuxStream(stream, process.stdout, process.stderr);
      stream.on("end", resolve);
      stream.on("error", reject);
      stream.resume(); // Drain output
    });
  });
  return;
}

export async function getLiveEnv(container) {
  const readEnvVar = await container.exec({
    Cmd: ["bash", "-c", "source /env-vars.sh && env"],
    AttachStdout: true,
    AttachStderr: true,
  });

  const output = await new Promise((resolve, reject) => {
    readEnvVar.start((err, stream) => {
      if (err) return reject(err);

      let stdout = "";
      let stderr = "";

      container.modem.demuxStream(
        stream,
        {
          write: (chunk) => {
            stdout += chunk.toString();
          },
        },
        {
          write: (chunk) => {
            stderr += chunk.toString();
          },
        }
      );

      stream.on("end", () => {
        if (stderr) return reject(new Error(stderr));
        resolve(stdout.trim());
      });

      stream.on("error", reject);
    });
  });

  const env = {};
  for (const envVar of output.split("\n")) {
    const [name, ...rest] = envVar.split("=");
    env[name] = rest.join("=");
  }
  return env;
}

export async function addEnvVariablesFromContainer(container, runtimeConfig) {
  const envVars = await getLiveEnv(container);

  for (var [name, value] of Object.entries(envVars)) {
    runtimeConfig.env[name] = value;
  }
}
