import debug from "debug";
import { CookieJar } from "tough-cookie";
import fetchCookie from "fetch-cookie";
import { Agent } from "undici";
import { FormData, File } from "formdata-node";
import fs from "fs";
import path from "path";
import { dirname } from "path";
import { fileURLToPath } from "url";

import { load } from "js-yaml";

import {
  setEnvVariable,
  executeCommand,
  getLiveEnv,
} from "../docker-helper.js";
import {
  captureCommand,
  captureDescription,
  captureInputText,
} from "./capture.js";
import {
  buildCurlCommand,
  isNetworkLevelError,
  parseCurlResponse,
} from "./container-request.js";
import {
  buildKubernetesResourceCommand,
  buildKubernetesResourcePropertyCommand,
  buildKubernetesWaitForCommand,
  checkKubernetesResourceCondition,
  compareKubernetesResourceProperty,
} from "./kubernetes-commands.js";
import { expectedHeaderChecks } from "./expected-headers.js";

const log = debug("tests:runner");
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const testsConfig = load(fs.readFileSync("./config/tests.yaml", "utf-8"));
const skipEnvVariables = new Set(
  testsConfig.validations?.skip_env_variables ?? [],
);

// Create cookie jar (in-memory)
const cookieJars = {};
const fetchInstances = {};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Bounded retry for container-executed assertions (customCommand and the
// kubernetes-* assertion types): 7 attempts with 10s-35s backoff (~2 minutes
// cumulative), tolerating reconciliation lag on freshly created resources.
const RETRY_DELAYS = [10000, 15000, 20000, 25000, 30000, 35000];

export class ValidationError extends Error {
  constructor(message, assertions) {
    super(message);
    this.name = "ValidationError";
    this.assertions = assertions;
  }
}

async function processHeaders(config, container) {
  const env = await getLiveEnv(container);
  let headers = {};
  if (config.headers) {
    config.headers.forEach((header) => {
      const [key, ...rest] = header.split(":");
      headers[key.trim()] = replaceEnvVars(rest.join(":").trim(), env);
    });
  }
  return headers;
}

function replaceEnvVars(object, variables) {
  function replaceVars(value) {
    if (typeof value === "string") {
      return value.replace(
        /\$(\w+)/g,
        (_, name) => variables[name] || `\$${name}`,
      );
    } else if (Array.isArray(value)) {
      return value.map(replaceVars);
    } else if (typeof value === "object") {
      const newObj = {};
      for (const key in value) {
        newObj[key] = replaceVars(value[key]);
      }
      return newObj;
    }
    return value;
  }

  return replaceVars(object);
}

function logAndError(validationName, message, expecations) {
  log(`   ${validationName} ❌. ${message}`);
  throw new ValidationError(
    `ValidationError: ${validationName}. ${message}`,
    expecations,
  );
}

function getSessionFromCookieHeader(header) {
  const match = header.match(/(session=[^;]+)/);
  return match ? match[1] : null;
}

async function runValueThroughCommand(container, value, command) {
  const encoded = Buffer.from(value).toString("base64");
  const cmd = `printf '%s' '${encoded}' | base64 -d | ${command}`;
  log(
    `[extract_headers] running command: ${cmd} (input=${JSON.stringify(value)})`,
  );
  const result = await executeCommand(container, cmd);
  log(`[extract_headers] command output: ${JSON.stringify(result.output)}`);
  return result.output.trim();
}

async function readFileContent(container, value, fileDir) {
  const filename = value.replace("@", "");
  const filesHostPath = path.resolve(
    __dirname,
    `../../../app/_includes/_files/${fileDir}`,
    filename,
  );

  if (fs.existsSync(filesHostPath)) {
    return fs.readFileSync(filesHostPath, "utf8");
  }

  const result = await executeCommand(container, `base64 "${filename}"`);
  return Buffer.from(result.output, "base64").toString("utf8");
}

async function fetchWithOptionalJar(url, options = {}, jarName) {
  if (jarName !== undefined) {
    if (!(jarName in cookieJars)) {
      cookieJars[jarName] = new CookieJar();
      fetchInstances[jarName] = fetchCookie(fetch, cookieJars[jarName]);
    }
    const fetchWithJar = fetchInstances[jarName];
    return fetchWithJar(url, options);
  }
  return fetch(url, options);
}

async function executeRequest(
  config,
  runtimeConfig,
  container,
  onResponse,
  expectedStatus,
) {
  const maxRetries =  process.env.MAX_RETRIES || 3;
  const initialRetryDelay = 5000; // 5 seconds initial delay

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    log(`Attempt ${attempt} to make request to ${config.url}`);
    const headers = await processHeaders(config, container);
    const env = await getLiveEnv(container);

    if (config.user) {
      const auth = Buffer.from(replaceEnvVars(config.user, env)).toString(
        "base64",
      );
      headers["Authorization"] = `Basic ${auth}`;
    }

    if (config.output) {
      headers["Accept-Encoding"] = "identity"; // Disable compression
    }
    const options = {
      method: config.method || "GET",
      headers,
      credentials: "include",
      redirect: "manual",
    };

    if (config.body !== undefined && options.method === "POST") {
      options.body = JSON.stringify(replaceEnvVars(config.body, env));
      headers["Content-Type"] = headers["Content-Type"] || "application/json";
    } else if (config.body_file !== undefined && options.method === "POST") {
      options.body = await readFileContent(
        container,
        config.body_file,
        config.file_dir,
      );
      headers["Content-Type"] = headers["Content-Type"] || "application/json";
    } else if (config.form_url_encoded_data !== undefined) {
      const params = new URLSearchParams();
      for (const [key, value] of Object.entries(config.form_url_encoded_data)) {
        params.append(key, replaceEnvVars(value, env));
      }
      options.body = params.toString();
      headers["Content-Type"] =
        headers["Content-Type"] || "application/x-www-form-urlencoded";
    } else if (config.form_data !== undefined) {
      const formData = new FormData();

      for (const [key, value] of Object.entries(config.form_data)) {
        if (key === "file") {
          const fileContent = await readFileContent(
            container,
            value,
            config.file_dir,
          );
          formData.append(key, new File([fileContent], value));
        } else {
          formData.append(key, replaceEnvVars(value, env));
        }
      }
      options.body = formData;
      // Let fetch set the correct Content-Type with boundary
      delete options.headers["Content-Type"];
    }
    const agent = new Agent({ connect: { rejectUnauthorized: false } });
    if (config.insecure) {
      options.dispatcher = agent;
    }

    const url = replaceEnvVars(config.url, env);

    if (config.debug) {
      console.log(`[debug] request: ${options.method} ${url}`);
      console.log(`[debug] request headers: ${JSON.stringify(headers)}`);
      if (options.body) console.log(`[debug] request body: ${options.body}`);
    }

    const jar = config.cookie_jar || config.cookie;
    let response;
    try {
      response = await fetchWithOptionalJar(url, options, jar);
    } catch (error) {
      const cause = error.cause
        ? ` (cause: ${error.cause.code || error.cause.message || error.cause})`
        : "";
      log(`[debug] fetch failed for ${options.method} ${url}${cause}`);
      console.error(
        `[debug] fetch failed for ${options.method} ${url}${cause}`,
      );
      error.message = `${error.message} for ${options.method} ${url}${cause}`;

      // The host fetch cannot reach Docker-internal addresses (on macOS, an
      // operator k3d bridge-network $PROXY_IP lives inside the Docker
      // Desktop VM's network). Re-run the same request inside the test
      // container, which shares the daemon's network namespace, and let the
      // parsed response flow through the normal status/extract/retry logic.
      // Classification and the curl/parse contracts live in
      // container-request.js; cookie-jar and multipart requests keep the
      // original error, since the fallback does not cover them.
      if (!isNetworkLevelError(error) || jar || options.body instanceof FormData) {
        throw error;
      }

      const fallbackCommand = buildCurlCommand(url, {
        ...options,
        insecure: config.insecure,
      });
      const fallbackMessage = `[fetch-fallback] ${options.method} ${url} is unreachable from the host; re-running inside the test container`;
      log(fallbackMessage);
      console.error(fallbackMessage);
      const result = await executeCommand(container, fallbackCommand);
      response = parseCurlResponse(result.output);
    }
    let body = {};

    if (response.status !== 302) {
      const text = await response.text();
      try {
        body = JSON.parse(text);
      } catch (e) {
        body = { message: text };
      }
    }

    if (config.debug) {
      console.log(`[debug] response status: ${response.status}`);
      console.log(`[debug] response body: ${JSON.stringify(body)}`);
    }

    // Extract headers and check if retry is needed
    let shouldRetry = false;
    if (config.extract_headers) {
      for (const header of config.extract_headers) {
        let extractedValue;
        if (header.name === "Set-Cookie") {
          extractedValue = getSessionFromCookieHeader(
            response.headers.get(header.name),
          );
        } else {
          extractedValue = response.headers.get(header.name);
        }

        if (header.command && extractedValue != null) {
          extractedValue = await runValueThroughCommand(
            container,
            extractedValue,
            header.command,
          );
        }

        if (
          config.retry &&
          (extractedValue === undefined ||
            extractedValue === "" ||
            extractedValue === null)
        ) {
          shouldRetry = true;
        } else {
          await setEnvVariable(container, header.variable, extractedValue);
          if (config.debug) {
            console.log(`extracted value: ${extractedValue}`);
          }
        }
      }
    }

    // Extract body and check if retry is needed
    if (config.extract_body) {
      for (const field of config.extract_body) {
        let value = field.name
          .split(".")
          .reduce((acc, key) => acc?.[key], body);

        if (field.strip_bearer) {
          value = value.replace(/bearer\s*/i, "");
        }

        if (
          config.retry &&
          (value === undefined || value === "" || value === null)
        ) {
          shouldRetry = true;
        } else {
          if (config.debug) {
            console.log(
              `extracted body field ${field.name} into ${field.variable}: ${value}`,
            );
          }
          await setEnvVariable(container, field.variable, value);
        }
      }
    }

    // Retry on a status code mismatch regardless of config.retry/extract_headers/extract_body
    if (expectedStatus !== undefined && response.status !== expectedStatus) {
      shouldRetry = true;
    }

    // Determine if request is successful
    const isSuccessful = !shouldRetry;

    if (isSuccessful) {
      return onResponse(response, body);
    }

    // If retry is needed and we haven't exhausted attempts
    if (attempt < maxRetries - 1) {
      const backoffDelay = initialRetryDelay * Math.pow(2, attempt);
      log(
        `Retry attempt ${
          attempt + 1
        } - extracted values were undefined/empty or status code ${
          response.status
        } did not match expected ${expectedStatus}, retrying in ${backoffDelay}ms...`,
      );
      await sleep(backoffDelay);
      continue;
    }

    // Max retries reached, return the last response
    log(`Max retries (${maxRetries}) reached, proceeding with last response`);
    return onResponse(response, body);
  }
}

async function validateRequest(
  validationName,
  config,
  runtimeConfig,
  container,
  checks,
  expectedStatus,
) {
  const assertions = [];

  await executeRequest(
    config,
    runtimeConfig,
    container,
    (response, body) => {
      for (const check of checks) {
        const { assert, message } = check(response, body);
        assertions.push(message);

        if (!assert) {
          assertions.push(body);
          logAndError(validationName, message, assertions);
        }
      }
    },
    expectedStatus,
  );
  return assertions;
}

async function rateLimit(validationName, config, runtimeConfig, container) {
  let assertions = [];

  for (let i = 0; i < config.iterations; i++) {
    const requestNumber = i + 1;
    const expectedStatus =
      requestNumber === config.iterations ? config.status_code : 200;

    const result = await validateRequest(
      validationName,
      config,
      runtimeConfig,
      container,
      [
        (response) => ({
          assert: response.status === expectedStatus,
          message: `Expected: request ${requestNumber} to have status code ${expectedStatus}, got: ${response.status}.`,
        }),
        ...(config.expected_headers
          ? expectedHeaderChecks(config.expected_headers, `request ${requestNumber}`)
          : []),
        ...(requestNumber === config.iterations
          ? [
              (response, body) => ({
                assert: body.message === config.message,
                message: `Expected: last request to have message '${config.message}', got: '${body.message}'.`,
              }),
            ]
          : []),
      ],
      expectedStatus,
    );
    assertions.push(...result);
    log(`     request #${requestNumber}: ✅ .`);
  }
  return assertions;
}

async function requestCheck(validationName, config, runtimeConfig, container) {
  if (config.sleep !== undefined) {
    console.log(`Sleeping for ${config.sleep} ms before making the request...`);
    await sleep(config.sleep);
  }
  const statusCode = config.status_code ?? 200;
  let responseText = "";
  const assertions = await validateRequest(
    validationName,
    config,
    runtimeConfig,
    container,
    [
      (response, body) => {
        if (config.capture) {
          responseText = captureInputText({
            status: response.status,
            headers: response.headers,
            // The response body arrives parsed for JSON responses;
            // re-serialize so the container-side shell pipeline sees the same
            // document.
            bodyText: typeof body === "string" ? body : JSON.stringify(body ?? ""),
            displayHeaders: Boolean(config.display_headers),
          });
        }
        return {
          assert: response.status === statusCode,
          message: `Expected: request ${config.url} to have status code ${statusCode}, got: ${response.status}.`,
        };
      },
      ...expectedHeaderChecks(config.expected_headers, `request to ${config.url}`),
    ],
    statusCode,
  );
  if (config.capture) {
    assertions.push(
      ...(await persistCapturedVariables(config.capture, config.url, responseText, container)),
    );
  }
  return assertions;
}

// `capture` entries on a request validation persist response fields as
// container env vars, so later steps can reference them ($CONTROL_PLANE_ID,
// $SERVICE_ID, ...). Every form the page renders is honored (see
// instructions/capture.js): a `jq` filter, a shell `command`, or the bare form
// that keeps the whole response as the value. The value is stored through the
// /env-vars.sh _BASE64 line format owned by instructions/export-assignment.js:
// multi-line values (certificates) survive, and decoded entries win over any
// earlier plain entry for the same name.
async function persistCapturedVariables(captures, url, responseText, container) {
  const assertions = [];

  for (const capture of captures) {
    if (!capture.variable) {
      throw new ValidationError(
        `Expected: capture entry to have 'variable', got: ${JSON.stringify(capture)}.`,
        assertions,
      );
    }
    const captureResult = await executeCommand(
      container,
      captureCommand(capture, responseText),
    );
    const value = captureResult.output.trim();

    if (!value || value === "null") {
      const message = `Expected: capture ${capture.variable} to produce a value with ${captureDescription(capture)}, got: empty.`;
      assertions.push(message);
      throw new ValidationError(message, assertions);
    }

    const base64Value = Buffer.from(value).toString("base64");
    await executeCommand(
      container,
      `echo 'export ${capture.variable}_BASE64="${base64Value}"' >> /env-vars.sh`,
    );
    assertions.push(
      `Captured ${capture.variable} from ${url} with ${captureDescription(capture)}.`,
    );
  }
  return assertions;
}

async function unauthorizedCheck(
  validationName,
  config,
  runtimeConfig,
  container,
) {
  return validateRequest(
    validationName,
    config,
    runtimeConfig,
    container,
    [
      (response) => ({
        assert: response.status === config.status_code,
        message: `Expected: request ${config.url} to have status code ${config.status_code}, got: ${response.status}.`,
      }),
      (response, body) => ({
        assert: body.message === config.message,
        message: `Expected: request to have message '${config.message}', got: '${body.message}'.`,
      }),
    ],
    config.status_code,
  );
}

async function envVariables(config, runtimeConfig, container) {
  for (const [key, value] of Object.entries(config)) {
    if (skipEnvVariables.has(key)) {
      continue;
    }
    await setEnvVariable(container, key, value);
  }

  return [];
}

async function quickstart(config, runtimeConfig, container) {
  const baseCommand = runtimeConfig.quickstart?.command;
  if (!baseCommand) {
    throw new Error(
      `No quickstart base command configured for ${runtimeConfig.deploymentModel}/${runtimeConfig.product}.`,
    );
  }

  const env = config.env || {};
  const flags = Object.entries(env)
    .map(([key, value]) => `-e "${key}=${value}"`)
    .join(" ");
  const command = flags ? `${baseCommand} ${flags}` : baseCommand;

  const result = await executeCommand(container, command);

  for (const match of result.output.matchAll(/^export (\w+)=(.*)$/gm)) {
    const [, name, value] = match;
    await setEnvVariable(container, name, value);
  }

  // Give the gateway time to boot before running validations against it.
  await sleep(5000);

  return [];
}

async function customCommand(validationName, config, runtimeConfig, container) {
  const returnCode = config.expected.return_code;
  const maxRetries = RETRY_DELAYS.length + 1;

  let result;
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      result = await executeCommand(container, config.command);
    } catch (error) {
      result = error;
    }

    const codeMatches = returnCode === result.exitCode;
    const messageMatches =
      !config.expected.message ||
      !result.output ||
      result.output.trimStart().includes(config.expected.message);

    if (codeMatches && messageMatches) {
      break;
    }

    if (attempt < maxRetries - 1) {
      const backoffDelay = RETRY_DELAYS[attempt];
      log(
        `Retry attempt ${
          attempt + 1
        } - command "${config.command}" did not meet expectations (exit code: ${
          result.exitCode
        }, output: ${result.output || "(empty)"}), retrying in ${backoffDelay}ms...`,
      );
      await sleep(backoffDelay);
    }
  }

  if (returnCode !== result.exitCode) {
    logAndError(validationName, "Failed to execute command", [
      `Expected: command to have return code ${returnCode}, got: ${result.exitCode}`,
      `Command: ${config.command}`,
      `Output: ${result.output || "(empty)"}`,
    ]);
  } else if (
    config.expected.message &&
    result.output &&
    !result.output.trimStart().includes(config.expected.message)
  ) {
    logAndError(validationName, "Command failed", [
      `Expected: the command's output to include ${config.expected.message}, got: ${result.output}`,
    ]);
  }
  return [];
}

async function trafficGenerator(
  validationName,
  config,
  runtimeConfig,
  container,
) {
  let assertions = [];

  for (let i = 0; i < config.iterations; i++) {
    const requestNumber = i + 1;
    const expectedStatus =
      config.status_code === undefined ? 200 : config.status_code;

    const result = await validateRequest(
      validationName,
      config,
      runtimeConfig,
      container,
      [
        (response) => ({
          assert: response.status === expectedStatus,
          message: `Expected: request ${requestNumber} to have status code ${expectedStatus}, got: ${response.status}.`,
        }),
      ],
      expectedStatus,
    );
    assertions.push(...result);
    log(`     request #${requestNumber}: ✅ .`);
  }
  return assertions;
}

async function vaultSecret(validationName, config, runtimeConfig, container) {
  let result;
  let expectedValue;

  let command = "";
  if (config.command) {
    command = `${config.command} kong vault get ${config.secret}`;
  } else {
    command = `docker exec ${config.container} kong vault get ${config.secret}`;
  }

  try {
    expectedValue = await executeCommand(container, `echo ${config.value}`);
    result = await executeCommand(container, command);
  } catch (error) {
    result = error;
  }
  if (result.exitCode !== 0) {
    logAndError(
      validationName,
      "Failed to retrieve the secret from the vault",
      [
        `Expected: command to have return code 0, got: ${result.exitCode}`,
        `Command: ${command}`,
        `Output: ${result.output || "(empty)"}`,
      ],
    );
  } else if (
    expectedValue &&
    result &&
    !result.output.trim().includes(expectedValue.output.trim())
  ) {
    logAndError(
      validationName,
      "Failed to retrieve the secret from the vault",
      [`Expected: the vault to return ${expectedValue}, got: ${result}`],
    );
  }
  return [];
}

// The kubernetes-* validations are thin hooks: required-config checks (the
// drop already validated them at render time, but a malformed step must fail
// before any cluster command runs), then exec of the helper-built command and
// delegation of the pass/fail decision to the helper's comparison. Command
// construction, defaults, and comparisons live in kubernetes-commands.js.
function requireKubernetesConfig(validationName, config, fields) {
  for (const field of fields) {
    // Falsy, not just null/undefined: an empty-string kind/name/path is a
    // de-facto missing field and must fail fast here, not burn the retry
    // budget on a kubectl error.
    if (!config[field]) {
      logAndError(
        validationName,
        `Missing '${field}' in the validation config: ${JSON.stringify(config)}.`,
        [],
      );
    }
  }
}

// The customCommand retry shape for the two assertion types: both read
// freshly created resources whose reconciliation may lag. kubernetes-wait-for
// does not use this: the wait itself is the retry mechanism, and kubectl's
// --timeout governs it (an outer loop would only multiply the timeout).
async function runKubernetesAssertion(container, command, evaluate) {
  const maxRetries = RETRY_DELAYS.length + 1;
  let result;
  let check;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      result = await executeCommand(container, command);
    } catch (error) {
      result = error;
    }

    check = evaluate(result.output);

    if (check.pass) {
      break;
    }

    if (attempt < maxRetries - 1) {
      log(
        `Retry attempt ${
          attempt + 1
        } - the kubernetes command did not pass yet (${check.message}), retrying in ${
          RETRY_DELAYS[attempt]
        }ms...`,
      );
      await sleep(RETRY_DELAYS[attempt]);
    }
  }

  return { check, command, output: result.output };
}

// Throws the ValidationError carrying the structured message on final
// failure; the assertions list keeps the check, the command, and the raw
// output so the report shows all three.
function reportKubernetesCheck(validationName, { check, command, output }) {
  if (!check.pass) {
    logAndError(validationName, check.message, [
      check.message,
      `Command: ${command}`,
      `Output: ${output || "(empty)"}`,
    ]);
  }
  return [check.message];
}

async function kubernetesResource(validationName, config, runtimeConfig, container) {
  requireKubernetesConfig(validationName, config, ["kind", "name"]);

  return reportKubernetesCheck(
    validationName,
    await runKubernetesAssertion(
      container,
      buildKubernetesResourceCommand(config),
      (commandOutput) => checkKubernetesResourceCondition(config, commandOutput),
    ),
  );
}

async function kubernetesResourceProperty(
  validationName,
  config,
  runtimeConfig,
  container,
) {
  requireKubernetesConfig(validationName, config, ["kind", "path"]);
  if (!config.name && !config.name_selector) {
    logAndError(
      validationName,
      `Missing 'name' or 'name_selector' in the validation config: ${JSON.stringify(config)}.`,
      [],
    );
  }

  return reportKubernetesCheck(
    validationName,
    await runKubernetesAssertion(
      container,
      buildKubernetesResourcePropertyCommand(config),
      (commandOutput) => compareKubernetesResourceProperty(config, commandOutput),
    ),
  );
}

async function kubernetesWaitFor(validationName, config, runtimeConfig, container) {
  requireKubernetesConfig(validationName, config, ["kind", "resource"]);

  const command = buildKubernetesWaitForCommand(config);
  let result;
  try {
    result = await executeCommand(container, command);
  } catch (error) {
    result = error;
  }

  if (result.exitCode !== 0) {
    // kubectl wait exits 0 once the condition is reached; anything else is
    // the timeout (or an error), and its first output line is kubectl's own
    // message naming the resource.
    const kubectlError = (result.output || "").trim().split("\n")[0];
    logAndError(
      validationName,
      `The kubectl wait failed or timed out: ${kubectlError || "(no output)"}`,
      [
        "Expected: the wait to complete within the configured timeout, got: " +
          `exit code ${result.exitCode} (the condition was not reached).`,
        `Command: ${command}`,
        `Output: ${result.output || "(empty)"}`,
      ],
    );
  }
  return [];
}

export async function validate(container, validation, runtimeConfig) {
  let result;
  log(`   ${validation.name}`);

  switch (validation.name) {
    case "rate-limit-check":
      result = await rateLimit(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "request-check":
    case "konnect-api-request":
    case "control_plane_request":
      result = await requestCheck(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "unauthorized-check":
      result = await unauthorizedCheck(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "env-variables":
      result = await envVariables(validation.config, runtimeConfig, container);
      break;
    case "quickstart":
      result = await quickstart(validation.config, runtimeConfig, container);
      break;
    case "custom-command":
    case "claude-code":
    case "codex":
    case "qwen":
    case "gemini":
      result = await customCommand(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "traffic-generator":
      result = await trafficGenerator(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "vault-secret":
      result = await vaultSecret(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "kubernetes-resource":
      result = await kubernetesResource(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "kubernetes-resource-property":
      result = await kubernetesResourceProperty(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    case "kubernetes-wait-for":
      result = await kubernetesWaitFor(
        validation.name,
        validation.config,
        runtimeConfig,
        container,
      );
      break;
    default:
      throw new Error(`Unsupported validation '${validation.name}'.`);
  }
  log(`   ${validation.name} ✅ .`);
  return result;
}
