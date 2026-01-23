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
                : debugLog(event.stream?.trim()),
          );
        },
      );
    });
  }
}

export async function executeCommand(container, cmd) {
  return new Promise(async (resolve, reject) => {
    try {
      // Get decoded environment variables
      const env = await getLiveEnv(container);

      // Convert to Docker Env format: ["KEY=value", "KEY2=value2"]
      const envArray = Object.entries(env).map(
        ([key, value]) => `${key}=${value}`,
      );

      const execCommand = await container.exec({
        Cmd: ["bash", "-c", cmd],
        AttachStdout: true,
        AttachStderr: true,
        Env: envArray,
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
  if (value === undefined) {
    console.log(
      `Value for ${name} is undefined, skipping setting this variable.`,
    );
    return;
  }

  let writeEnvVar;

  // If value is a command substitution, execute it and handle the result
  if (value.trim().startsWith("$(") && value.trim().endsWith(")")) {
    const command = value.trim().slice(2, -1);
    const result = await executeCommand(container, command);
    const output = result.output.trim();

    // Convert literal \n to actual newlines
    const withNewlines = output.replace(/\\n/g, "\n");

    // Base64 encode to safely store in env file
    const base64Value = Buffer.from(withNewlines).toString("base64");

    writeEnvVar = await container.exec({
      Cmd: [
        "bash",
        "-c",
        `echo 'export ${name}_BASE64="${base64Value}"' >> /env-vars.sh`,
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
        stream.resume();
      });
    });
    return;
  } else {
    writeEnvVar = await container.exec({
      Cmd: [
        "bash",
        "-c",
        `echo 'export ${name}="${value}"' | cat >> /env-vars.sh`,
      ],
      AttachStdout: true,
      AttachStderr: true,
    });
  }

  await new Promise((resolve, reject) => {
    writeEnvVar.start((err, stream) => {
      if (err) return reject(err);

      container.modem.demuxStream(stream, process.stdout, process.stderr);
      stream.on("end", resolve);
      stream.on("error", reject);
      stream.resume();
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
        },
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
    let value = rest.join("=");

    // Decode base64-encoded values and store with original name
    if (name.endsWith("_BASE64")) {
      const originalName = name.slice(0, -7); // Remove _BASE64 suffix
      env[originalName] = Buffer.from(value, "base64").toString("utf-8");
    } else {
      env[name] = value;
    }
  }
  return env;
}
