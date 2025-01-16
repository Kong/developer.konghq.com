import fetch from "node-fetch";
import debug from "debug";
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

function logAndError(validationName, message, expecations) {
  log(`   ${validationName} ❌. ${message}`);
  throw new ValidationError(
    `ValidationError: ${validationName}. ${message}`,
    expecations
  );
}

async function executeRequest(config, onResponse) {
  const headers = processHeaders(config);
  const response = await fetch(config.url, { headers });
  const body = await response.json();

  return onResponse(response, body);
}

async function validateRequest(validationName, config, checks) {
  const assertions = [];

  await executeRequest(config, (response, body) => {
    for (const check of checks) {
      const { assert, message } = check(response, body);
      assertions.push(message);
      if (!assert) {
        logAndError(validationName, message, assertions);
      }
    }
  });
  return assertions;
}

async function rateLimit(validationName, config) {
  let assertions = [];

  for (let i = 0; i < config.iterations; i++) {
    const requestNumber = i + 1;
    const expectedStatus =
      requestNumber === config.iterations ? config.status_code : 200;

    const result = await validateRequest(validationName, config, [
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
    ]);
    assertions.push(...result);
    log(`     request #${requestNumber}: ✅ .`);
  }
  return assertions;
}

async function requestCheck(validationName, config) {
  return validateRequest(validationName, config, [
    (response) => ({
      assert: response.status === config.status_code,
      message: `Expected: request ${config.url} to have status code ${config.status_code}, got: ${response.status}.`,
    }),
  ]);
}

async function unauthorizedCheck(validationName, config) {
  return validateRequest(validationName, config, [
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

export async function validate(validation) {
  let result;
  log(`   ${validation.name}`);

  switch (validation.name) {
    case "rate-limit-check":
      result = await rateLimit(validation.name, validation.config);
      break;
    case "request-check":
      result = await requestCheck(validation.name, validation.config);
      break;
    case "unauthorized-check":
      result = await unauthorizedCheck(validation.name, validation.config);
      break;
    default:
      throw new Error(`Unsupported validation '${validation.name}'.`);
  }
  log(`   ${validation.name} ✅ .`);
  return result;
}
