import fetch from "node-fetch";
import debug from "debug";
import { runtimeEnvironment } from "../runtimes.js";

const log = debug("tests:runner");

export class ValidationError extends Error {
  constructor(message, assertions) {
    super(message);
    this.name = "ValidationError";
    this.assertions = assertions;
  }
}

function processHeaders(config) {
  let headers = {};
  if (config.headers) {
    config.headers.forEach((header) => {
      const [key, value] = header.split(":");
      headers[key] = value;
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
  console.error(` ${validationName} ❌. ${message}`);
  throw new ValidationError(
    `ValidationError: ${validationName}. ${message}`,
    expecations
  );
}

async function executeRequest(config, runtimeConfig, onResponse) {
  const headers = processHeaders(config);
  const options = { method: config.method || "GET", headers };

  if (config.body && options.method === "POST") {
    const env = await runtimeEnvironment(runtimeConfig);
    options.body = JSON.stringify(replaceEnvVars(config.body, env));
    headers["Content-Type"] = headers["Content-Type"] || "application/json";
  }

  const response = await fetch(config.url, options);
  const body = await response.json();

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

export async function validate(validation, runtimeConfig) {
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
    default:
      throw new Error(`Unsupported validation '${validation.name}'.`);
  }
  log(`   ${validation.name} ✅ .`);
  return result;
}
