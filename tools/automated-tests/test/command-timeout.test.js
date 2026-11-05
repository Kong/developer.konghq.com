import test from "node:test";
import assert from "node:assert/strict";
import { withTimeout } from "../instructions/command-timeout.js";

test("withTimeout returns the original promise when no timeout is given", async () => {
  const promise = Promise.resolve("done");

  assert.strictEqual(await withTimeout(promise, 0), "done");
  assert.strictEqual(await withTimeout(promise, undefined), "done");
});

test("withTimeout resolves with the command result when the command finishes first", async () => {
  const command = new Promise((resolve) =>
    setTimeout(() => resolve("done"), 10),
  );

  assert.strictEqual(await withTimeout(command, 1000, { message: "timed out" }), "done");
});

test("withTimeout rejects with the provided message when the timeout fires", async () => {
  const command = new Promise(() => {});
  const onTimeout = () => {};

  await assert.rejects(
    withTimeout(command, 10, { message: "timed out", onTimeout }),
    /timed out/,
  );
});

test("withTimeout calls onTimeout when the timeout fires", async () => {
  const command = new Promise(() => {});
  let called = false;
  const onTimeout = () => {
    called = true;
  };

  await withTimeout(command, 10, { onTimeout }).catch(() => {});

  assert.ok(called);
});

test("withTimeout propagates a command failure that happens before the timeout", async () => {
  const command = Promise.reject(new Error("command failed"));

  await assert.rejects(
    withTimeout(command, 1000, { message: "timed out" }),
    /command failed/,
  );
});

test("withTimeout does not keep a pending rejection around after the command wins", async () => {
  const command = Promise.resolve("done");

  assert.strictEqual(
    await withTimeout(command, 10000, { message: "timed out" }),
    "done",
  );
});
