import { test } from "node:test";
import assert from "node:assert/strict";

import {
  parseRetryCount,
  computeRetryDelay,
  retryWithBackoff,
  INITIAL_RETRY_DELAY_MS,
  MAX_RETRY_DELAY_MS,
} from "../instructions/retry.js";

test("parses a retry count attribute", () => {
  assert.equal(parseRetryCount("6"), 6);
  assert.equal(parseRetryCount("1"), 1);
});

test("returns null when the retry count is absent", () => {
  assert.equal(parseRetryCount(null), null);
  assert.equal(parseRetryCount(undefined), null);
});

test("returns null for invalid retry counts", () => {
  assert.equal(parseRetryCount("abc"), null);
  assert.equal(parseRetryCount("0"), null);
  assert.equal(parseRetryCount("-3"), null);
  assert.equal(parseRetryCount("2.5"), null);
  assert.equal(parseRetryCount(""), null);
});

test("computes exponential backoff delays capped at 30s", () => {
  assert.equal(computeRetryDelay(1), 5000);
  assert.equal(computeRetryDelay(2), 10000);
  assert.equal(computeRetryDelay(3), 20000);
  assert.equal(computeRetryDelay(4), MAX_RETRY_DELAY_MS);
  assert.equal(computeRetryDelay(10), MAX_RETRY_DELAY_MS);
  assert.equal(INITIAL_RETRY_DELAY_MS, 5000);
  assert.equal(MAX_RETRY_DELAY_MS, 30000);
});

test("returns the task result without retrying when it succeeds", async () => {
  let calls = 0;
  const sleeps = [];
  const retries = [];
  const result = await retryWithBackoff(async () => {
    calls++;
    return "ok";
  }, {
    count: 5,
    sleepFn: async (ms) => sleeps.push(ms),
    onRetry: (info) => retries.push(info),
  });
  assert.equal(result, "ok");
  assert.equal(calls, 1);
  assert.deepEqual(sleeps, []);
  assert.deepEqual(retries, []);
});

test("retries with backoff until the task succeeds", async () => {
  let calls = 0;
  const sleeps = [];
  const retries = [];
  await retryWithBackoff(
    async () => {
      calls++;
      if (calls < 3) {
        throw new Error(`failure ${calls}`);
      }
      return "ok";
    },
    {
      count: 5,
      sleepFn: async (ms) => sleeps.push(ms),
      onRetry: ({ attempt, delay, error }) => retries.push({ attempt, delay, error: error.message }),
    },
  );
  assert.equal(calls, 3);
  assert.deepEqual(sleeps, [5000, 10000]);
  assert.deepEqual(retries, [
    { attempt: 1, delay: 5000, error: "failure 1" },
    { attempt: 2, delay: 10000, error: "failure 2" },
  ]);
});

test("throws the last error after every attempt fails", async () => {
  let calls = 0;
  const retries = [];
  await assert.rejects(
    retryWithBackoff(
      async () => {
        calls++;
        throw new Error(`failure ${calls}`);
      },
      {
        count: 3,
        sleepFn: async () => {},
        onRetry: ({ attempt }) => retries.push(attempt),
      },
    ),
    (error) => {
      assert.equal(error.message, "failure 3");
      return true;
    },
  );
  assert.equal(calls, 3);
  assert.deepEqual(retries, [1, 2]);
});

test("runs the task once when count is 1", async () => {
  let calls = 0;
  await assert.rejects(
    retryWithBackoff(
      async () => {
        calls++;
        throw new Error("nope");
      },
      { count: 1, sleepFn: async () => {}, onRetry: () => assert.fail("onRetry must not be called") },
    ),
    /nope/,
  );
  assert.equal(calls, 1);
});

test("honors an injected delay function", async () => {
  const delays = [];
  await retryWithBackoff(async () => {
    throw new Error("fail");
  }, {
    count: 3,
    computeDelay: () => 1,
    sleepFn: async (ms) => delays.push(ms),
    onRetry: () => {},
  }).catch(() => {});
  assert.deepEqual(delays, [1, 1]);
});
