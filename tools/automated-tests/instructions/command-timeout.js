// Guards a single command execution with a wall-clock timeout. A command can
// hang indefinitely without this: `kubectl delete` on a namespace wedged in
// Terminating by a stuck finalizer never returns, and a hung exec stream has
// nothing else that would ever fail it. onTimeout lets the caller tear down
// the underlying stream so the container-side output stops buffering.
export function withTimeout(promise, timeoutMs, { message, onTimeout } = {}) {
  if (!timeoutMs) {
    return promise;
  }

  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      if (onTimeout) {
        onTimeout();
      }
      reject(new Error(message ?? `Timed out after ${timeoutMs}ms`));
    }, timeoutMs);
  });

  // finally clears the timer when either side settles, so a command that
  // wins the race never leaves a pending rejection behind.
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}
