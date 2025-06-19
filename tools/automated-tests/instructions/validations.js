import fetch from "node-fetch";
import debug from "debug";
import https from "https";
import tough from "tough-cookie";
import fetchCookie from "fetch-cookie";

import { runtimeEnvironment } from "../runtimes.js";
import {
  setEnvVariable,
  addEnvVariablesFromContainer,
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

async function processHeaders(config, runtimeConfig) {
  const env = await runtimeEnvironment(runtimeConfig);
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

async function executeRequest(config, runtimeConfig, onResponse) {
  const headers = await processHeaders(config, runtimeConfig);
  const env = await runtimeEnvironment(runtimeConfig);
  if (config.user) {
    const auth = Buffer.from(replaceEnvVars(config.user, env)).toString(
      "base64"
    );
    headers["Authorization"] = `Basic ${auth}`;
  }
  const options = {
    method: config.method || "GET",
    headers,
    redirect: "manual",
  };

  if (config.body && options.method === "POST") {
    options.body = JSON.stringify(replaceEnvVars(config.body, env));
    headers["Content-Type"] = headers["Content-Type"] || "application/json";
  }

  const agent = new https.Agent({ rejectUnauthorized: false });
  if (config.insecure) {
    options["agent"] = agent;
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
        runtimeConfig.env[header.variable] = getSessionFromCookieHeader(
          response.headers.get(header.name)
        );
      } else {
        runtimeConfig.env[header.variable] = response.headers.get(header.name);
      }
    }
  }

  if (config.extract_body) {
    for (const field of config.extract_body) {
      let value = field.name.split(".").reduce((acc, key) => acc?.[key], body);

      if (field.strip_bearer) {
        value = value.replace(/bearer\s*/i, "");
      }

      runtimeConfig.env[field.variable] = value;
    }
  }

  return onResponse(response, body);
}

async function validateRequest(validationName, config, runtimeConfig, checks) {
  const assertions = [];

  await executeRequest(config, runtimeConfig, (response, body) => {
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

async function rateLimit(validationName, config, runtimeConfig) {
  let assertions = [];

  for (let i = 0; i < config.iterations; i++) {
    const requestNumber = i + 1;
    const expectedStatus =
      requestNumber === config.iterations ? config.status_code : 200;

    const result = await validateRequest(
      validationName,
      config,
      runtimeConfig,
      [
        (response) => ({
          assert: response.status === expectedStatus,
          message: `Expected: request ${requestNumber} to have status code ${expectedStatus}, got: ${response.status}.`,
        }),
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

async function requestCheck(validationName, config, runtimeConfig) {
  return validateRequest(validationName, config, runtimeConfig, [
    (response) => ({
      assert: response.status === config.status_code,
      message: `Expected: request ${config.url} to have status code ${config.status_code}, got: ${response.status}.`,
    }),
  ]);
}

async function unauthorizedCheck(validationName, config, runtimeConfig) {
  return validateRequest(validationName, config, runtimeConfig, [
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
  await addEnvVariablesFromContainer(container, runtimeConfig);
  return [];
}

async function controlPlaneRequest(validationName, config, runtimeConfig) {
  const statusCode =
    config.status_code !== undefined ? config.status_code : 200;
  return validateRequest(validationName, config, runtimeConfig, [
    (response) => ({
      assert: response.status === statusCode,
      message: `Expected: request ${config.url} to have status code ${statusCode}, got: ${response.status}.`,
    }),
  ]);
}

async function customCommand(validationName, config, runtimeConfig, container) {
  const returnCode = config.expected.return_code;
  const result = await executeCommand(container, config.command);
  if (returnCode !== result) {
    logAndError(
      validationName,
      message,
      `Expected: command to have return code ${returnCode}, got: ${result}`
    );
  }
  return [];
}

async function trafficGenerator(validationName, config, runtimeConfig) {
  let assertions = [];

  for (let i = 0; i < config.iterations; i++) {
    const requestNumber = i + 1;
    const expectedStatus =
      config.status_code === undefined ? 200 : config.status_code;

    const result = await validateRequest(
      validationName,
      config,
      runtimeConfig,
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

export async function validate(container, validation, runtimeConfig) {
  let result;
  log(`   ${validation.name}`);

  switch (validation.name) {
    case "rate-limit-check":
      result = await rateLimit(
        validation.name,
        validation.config,
        runtimeConfig
      );
      break;
    case "request-check":
      result = await requestCheck(
        validation.name,
        validation.config,
        runtimeConfig
      );
      break;
    case "unauthorized-check":
      result = await unauthorizedCheck(
        validation.name,
        validation.config,
        runtimeConfig
      );
      break;
    case "env-variables":
      result = await envVariables(validation.config, runtimeConfig, container);
      break;
    case "control_plane_request":
      result = await controlPlaneRequest(
        validation.name,
        validation.config,
        runtimeConfig
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
        runtimeConfig
      );
      break;
    default:
      throw new Error(`Unsupported validation '${validation.name}'.`);
  }
  log(`   ${validation.name} ✅ .`);
  return result;
}
