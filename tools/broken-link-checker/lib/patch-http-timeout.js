// Adds a default per-socket inactivity timeout to every outgoing http/https
// request. The link checker uses broken-link-checker@0.7.8 → bhttp, which
// does not pass a responseTimeout and has no way to configure one from its
// public API. When the target server (typically a Netlify deploy preview
// under load) opens the connection but never responds, the request hangs
// forever and the SiteChecker / HtmlUrlChecker `end` event never fires —
// stalling CI until GitHub kills the job at the workflow timeout.

import http from "node:http";
import https from "node:https";

const TIMEOUT_MS = 30_000;

function patch(mod) {
  const orig = mod.request;
  mod.request = function patchedRequest(...args) {
    const req = orig.apply(this, args);
    req.setTimeout(TIMEOUT_MS, () => {
      // Skip if the request already finished — a late timer on a pooled
      // keep-alive socket would otherwise emit 'error' on a ClientRequest
      // whose listener bhttp has already detached, crashing the process.
      if (req.destroyed || req.res?.complete) return;
      const err = new Error(`socket inactivity timeout after ${TIMEOUT_MS}ms`);
      // Set .code so broken-link-checker classifies this as ERRNO_ETIMEDOUT
      // (see node_modules/broken-link-checker/lib/internal/checkUrl.js)
      // rather than BLC_UNKNOWN / "Unknown Error".
      err.code = "ETIMEDOUT";
      req.destroy(err);
    });
    return req;
  };
}

patch(http);
patch(https);
