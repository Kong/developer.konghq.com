import fetch from "node-fetch";
import debug from "debug";
import yaml from "js-yaml";
const log = debug("runner");

export class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = "ValidationError";
  }
}

function processHeaders(config) {
  let headers = {};
  config.headers.forEach((header) => {
    const [key, value] = header.split(":");
    headers[key] = value;
  });

  return headers;
}

function logAndError(message) {
  log(`   rate-limit-check ❌. ${message}`);
  throw new ValidationError(`ValidationError: rate-limit-check. ${message}`);
}

async function rateLimit(config) {
  log("   rate-limit-check:");
  const headers = processHeaders(config);

  for (let i = 0; i < config.iterations; i++) {
    const response = await fetch(config.url, { headers });
    const body = await response.json();
    const requestNumber = i + 1;
    if (i === config.iterations - 1) {
      if (response.status !== config.status_code) {
        const message = `Expected: last request to have a status code equal to ${config.status_code}, got: ${response.status}.`;
        logAndError(message);
      }

      if (body.message !== config.message) {
        const message = `Expected: last request to have message: ${config.message}, got: ${body.message}.`;
        logAndError(message);
      }
      log(`     request #${requestNumber}: ✅ .`);
      log(`   rate-limit-check ✅ .`);
    } else {
      if (response.status !== 200) {
        log(`     request #${requestNumber}: ❌ .`);
        const message = `Expected: request #${requestNumber} to have a status code equal to 200, got: ${response.status}.`;
        logAndError(message);
      } else {
        log(`     request #${requestNumber}: ✅ .`);
      }
    }
  }
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
