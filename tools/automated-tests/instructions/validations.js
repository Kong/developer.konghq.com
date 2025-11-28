import debug from "debug";
import tough from "tough-cookie";
import fetchCookie from "fetch-cookie";
import { Agent } from "undici";

import {
  setEnvVariable,
  executeCommand,
  getLiveEnv,
} from "../docker-helper.js";

const log = debug("tests:runner");

// Create cookie jar (in-memory)
const cookieJars = {};
const fetchInstances = {};

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
      const [key, value] = header.split(":");
      headers[key] = replaceEnvVars(value, env);
    });
  }
  return headers;
}

function replaceEnvVars(object, variables) {
  function replaceVars(value) {
    if (typeof value === "string") {
      return value.replace(
        /\$(\w+)/g,
        (_, name) => variables[name] || `\$${name}`
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
    expecations
  );
}

function getSessionFromCookieHeader(header) {
  const match = header.match(/(session=[^;]+)/);
  return match ? match[1] : null;
}

async function fetchWithOptionalJar(url, options = {}, jarName) {
  if (jarName !== undefined) {
    if (!(jarName in cookieJars)) {
      cookieJars[jarName] = new tough.CookieJar();
      fetchInstances[jarName] = fetchCookie(fetch, cookieJars[jarName]);
    }
    const fetchWithJar = fetchInstances[jarName];
    return fetchWithJar(url, options);
  }
  return fetch(url, options);
}

async function executeRequest(config, runtimeConfig, container, onResponse) {
  const headers = await processHeaders(config, container);
  const env = await getLiveEnv(container);

  if (config.user) {
    const auth = Buffer.from(replaceEnvVars(config.user, env)).toString(
      "base64"
    );
    headers["Authorization"] = `Basic ${auth}`;
  }
  const options = {
    method: config.method || "GET",
    headers,
    credentials: "include",
    redirect: "manual",
  };

  if (config.body && options.method === "POST") {
    options.body = JSON.stringify(replaceEnvVars(config.body, env));
    headers["Content-Type"] = headers["Content-Type"] || "application/json";
  }

  const agent = new Agent({ connect: { rejectUnauthorized: false } });
  if (config.insecure) {
    options.dispatcher = agent;
  }

  const url = replaceEnvVars(config.url, env);

  const response = await fetchWithOptionalJar(
    url,
    options,
    config.cookie_jar || config.cookie
  );
  let body = {};
  if (response.status !== 302) {
    const text = await response.text();
    try {
      body = JSON.parse(text);
    } catch (e) {
      body = { message: text };
    }
  }

  if (config.extract_headers) {
    for (const header of config.extract_headers) {
      if (header.name === "Set-Cookie") {
        await setEnvVariable(
          container,
          header.variable,
          getSessionFromCookieHeader(response.headers.get(header.name))
        );
      } else {
        await setEnvVariable(
          container,
          header.variable,
          response.headers.get(header.name)
        );
      }
    }
  }

  if (config.extract_body) {
    for (const field of config.extract_body) {
      let value = field.name.split(".").reduce((acc, key) => acc?.[key], body);

      if (field.strip_bearer) {
        value = value.replace(/bearer\s*/i, "");
      }
      await setEnvVariable(container, field.variable, value);
    }
  }

  return onResponse(response, body);
}

async function validateRequest(
  validationName,
  config,
  runtimeConfig,
  container,
  checks
) {
  const assertions = [];

  await executeRequest(config, runtimeConfig, container, (response, body) => {
    for (const check of checks) {
      const { assert, message } = check(response, body);
      assertions.push(message);

      if (!assert) {
        assertions.push(body);
        logAndError(validationName, message, assertions);
      }
    }
  });
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
          ? config.expected_headers.map((header) => (response) => ({
              assert: response.headers.has(header),
              message: `Expected: request ${requestNumber} to have header '${header}', got: '${response.headers.get(
                header
              )}'.`,
            }))
          : []),
        ...(requestNumber === config.iterations
          ? [
              (response, body) => ({
                assert: body.message === config.message,
                message: `Expected: last request to have message '${config.message}', got: '${body.message}'.`,
              }),
            ]
          : []),
      ]
    );
    assertions.push(...result);
    log(`     request #${requestNumber}: ✅ .`);
  }
  return assertions;
}

async function requestCheck(validationName, config, runtimeConfig, container) {
  return validateRequest(validationName, config, runtimeConfig, container, [
    (response) => ({
      assert: response.status === config.status_code,
      message: `Expected: request ${config.url} to have status code ${config.status_code}, got: ${response.status}.`,
    }),
  ]);
}

async function unauthorizedCheck(
  validationName,
  config,
  runtimeConfig,
  container
) {
  return validateRequest(validationName, config, runtimeConfig, container, [
    (response) => ({
      assert: response.status === config.status_code,
      message: `Expected: request ${config.url} to have status code ${config.status_code}, got: ${response.status}.`,
    }),
    (response, body) => ({
      assert: body.message === config.message,
      message: `Expected: request to have message '${config.message}', got: '${body.message}'.`,
    }),
  ]);
}

async function envVariables(config, runtimeConfig, container) {
  for (const [key, value] of Object.entries(config)) {
    if (key === "KONG_LICENSE_DATA") {
      continue;
    }
    await setEnvVariable(container, key, value);
  }

  return [];
}

async function controlPlaneRequest(
  validationName,
  config,
  runtimeConfig,
  container
) {
  const statusCode =
    config.status_code !== undefined ? config.status_code : 200;
  return validateRequest(validationName, config, runtimeConfig, container, [
    (response) => ({
      assert: response.status === statusCode,
      message: `Expected: request ${config.url} to have status code ${statusCode}, got: ${response.status}.`,
    }),
  ]);
}

async function customCommand(validationName, config, runtimeConfig, container) {
  const returnCode = config.expected.return_code;
  let result;
  try {
    result = await executeCommand(container, config.command);
  } catch (error) {
    result = error;
  }
  if (returnCode !== result.exitCode) {
    logAndError(validationName, "Failed to execute command", [
      `Expected: command to have return code ${returnCode}, got: ${result.exitCode}`,
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
  container
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
      ]
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
      [`Expected: command to have return code 0, got: ${result.exitCode}`]
    );
  } else if (
    expectedValue &&
    result &&
    !result.output.trim().includes(expectedValue.output.trim())
  ) {
    logAndError(
      validationName,
      "Failed to retrieve the secret from the vault",
      [`Expected: the vault to return ${expectedValue}, got: ${result}`]
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
        container
      );
      break;
    case "request-check":
    case "konnect-api-request":
      result = await requestCheck(
        validation.name,
        validation.config,
        runtimeConfig,
        container
      );
      break;
    case "unauthorized-check":
      result = await unauthorizedCheck(
        validation.name,
        validation.config,
        runtimeConfig,
        container
      );
      break;
    case "env-variables":
      result = await envVariables(validation.config, runtimeConfig, container);
      break;
    case "control_plane_request":
      result = await controlPlaneRequest(
        validation.name,
        validation.config,
        runtimeConfig,
        container
      );
      break;
    case "custom-command":
      result = await customCommand(
        validation.name,
        validation.config,
        runtimeConfig,
        container
      );
      break;
    case "traffic-generator":
      result = await trafficGenerator(
        validation.name,
        validation.config,
        runtimeConfig,
        container
      );
      break;
    case "vault-secret":
      result = await vaultSecret(
        validation.name,
        validation.config,
        runtimeConfig,
        container
      );
      break;
    default:
      throw new Error(`Unsupported validation '${validation.name}'.`);
  }
  log(`   ${validation.name} ✅ .`);
  return result;
}
