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

function logAndError(message, expecations) {
  log(`   rate-limit-check ❌. ${message}`);
  throw new ValidationError(
    `ValidationError: rate-limit-check. ${message}`,
    expecations
  );
}

async function rateLimit(config) {
  let assertions = [];
  log("   rate-limit-check:");
  const headers = processHeaders(config);

  for (let i = 0; i < config.iterations; i++) {
    const response = await fetch(config.url, { headers });
    const body = await response.json();
    const requestNumber = i + 1;

    const statusCode =
      requestNumber === config.iterations ? config.status_code : 200;
    const assertion = `Expected: request ${requestNumber} to have a status code equal to ${statusCode}, got: ${response.status}.`;
    assertions.push(assertion);

    if (statusCode !== response.status) {
      log(`     request #${requestNumber}: ❌ .`);
      logAndError(assertion, assertions);
    }
    if (i === config.iterations - 1) {
      const messageAssertion = `Expected: last request to have message: '${config.message}', got: '${body.message}'.`;
      assertions.push(messageAssertion);
      if (body.message !== config.message) {
        logAndError(messageAssertion, assertions);
      }
    }
    log(`     request #${requestNumber}: ✅ .`);
  }
  log(`   rate-limit-check ✅ .`);
  return assertions;
}

export async function validate(validation) {
  let result;

  switch (validation.name) {
    case "rate-limit-check":
      result = await rateLimit(validation.config);
      break;
    default:
      throw new Error(`Unsupported validation '${validation.name}'.`);
  }

  return result;
}
