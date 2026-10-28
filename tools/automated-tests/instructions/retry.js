import debug from "debug";

import { executeDocCommand } from "../docker-helper.js";

const log = debug("tests:runner");
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Owns retry behavior for doc-sourced command steps.
//
// A step fence marked with data-test-retry-count extracts into a structured
// step ({ command, retry_count }): readers see and copy only the plain
// command, and the runner repeats it until it succeeds or the attempts run
// out. This mirrors executeRequest in validations.js: a 5s initial delay
// doubling per failed attempt, capped at 30s, so six attempts cover roughly
// the 95s window of a data plane re-provision plus route programming.
//
// Every attempt goes through executeDocCommand, so export persistence
// (export-assignment.js) works on the successful attempt and the block's own
// output prints on every attempt. The final failure propagates with the last
// attempt's exit code and output.

export const INITIAL_RETRY_DELAY_MS = 5000;
export const MAX_RETRY_DELAY_MS = 30000;

export function parseRetryCount(value) {
  if (value === null || value === undefined || !/^\d+$/.test(value)) {
    return null;
  }
  const count = Number.parseInt(value, 10);
  return count >= 1 ? count : null;
}

export function computeRetryDelay(attempt) {
  return Math.min(
    INITIAL_RETRY_DELAY_MS * 2 ** (attempt - 1),
    MAX_RETRY_DELAY_MS,
  );
}

export async function retryWithBackoff(
  task,
  { count, computeDelay = computeRetryDelay, onRetry = () => {}, sleepFn = sleep },
) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await task();
    } catch (error) {
      if (attempt >= count) {
        throw error;
      }
      const delay = computeDelay(attempt);
      onRetry({ attempt, delay, error });
      await sleepFn(delay);
    }
  }
}

export async function executeDocCommandWithRetry(container, command, count) {
  const attempts = Number.isInteger(count) && count >= 1 ? count : 1;
  return retryWithBackoff(() => executeDocCommand(container, command), {
    count: attempts,
    onRetry: ({ attempt, delay }) => {
      const firstLine = command.split("\n")[0];
      log(
        `Retry attempt ${attempt + 1}/${attempts} - command "${firstLine}" failed, retrying in ${delay}ms...`,
      );
    },
  });
}
