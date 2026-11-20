import { afterEach, beforeEach, describe, it, mock } from "node:test";
import assert from "node:assert/strict";

import { sendEvent, type AnalyticsEvent } from "../../../netlify/utils/analytics.ts";

const event: AnalyticsEvent = {
  x_edge_request_id: "01HZX3",
  logged_at_utc: "2026-11-20T14:03:12Z",
  x_host_header: "developer.konghq.com",
  cs_uri_stem: "/kongctl/",
  sc_status: 200,
  cs_user_agent: "curl/8.0",
  c_ip: "203.0.113.42",
  cs_method: "GET",
  cs_referer_domain: "www.google.com",
  cs_uri_query_utm_ktm: "utm_source=x",
  sc_content_type: "text/html; charset=utf-8",
};

type FetchCall = { url: string; init: RequestInit };

const setEnv = (vars: Record<string, string>) => {
  (globalThis as any).Netlify = { env: { get: (key: string) => vars[key] } };
};

describe("sendEvent", () => {
  let calls: FetchCall[];
  let fetchImpl: (url: string, init: RequestInit) => Promise<Response>;

  beforeEach(() => {
    calls = [];
    fetchImpl = async () => new Response(null, { status: 204 });
    (globalThis as any).fetch = (url: string, init: RequestInit) => {
      calls.push({ url, init });
      return fetchImpl(url, init);
    };
    setEnv({
      ANALYTICS_ENDPOINT_URL: "https://analytics.example.test/events",
      ANALYTICS_API_KEY: "secret-key",
    });
  });

  afterEach(() => {
    mock.restoreAll();
    delete (globalThis as any).Netlify;
  });

  it("POSTs the event as JSON with the auth header", async () => {
    await sendEvent(event);

    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, "https://analytics.example.test/events");
    assert.equal(calls[0].init.method, "POST");
    const headers = new Headers(calls[0].init.headers);
    assert.equal(headers.get("content-type"), "application/json");
    assert.equal(headers.get("x-api-key"), "secret-key");
    const body = JSON.parse(calls[0].init.body as string);
    assert.deepEqual(body, event);
    assert.deepEqual(Object.keys(body).sort(), Object.keys(event).sort());
    assert.equal(Object.keys(body).length, 11);
    assert.equal(typeof body.sc_status, "number");
  });

  it("calls no fetch when the URL is unset", async () => {
    setEnv({ ANALYTICS_API_KEY: "secret-key" });

    await sendEvent(event);

    assert.equal(calls.length, 0);
  });

  it("calls no fetch when the key is unset", async () => {
    setEnv({ ANALYTICS_ENDPOINT_URL: "https://analytics.example.test/events" });

    await sendEvent(event);

    assert.equal(calls.length, 0);
  });

  it("resolves when fetch rejects", async () => {
    fetchImpl = async () => {
      throw new Error("connection refused");
    };

    await assert.doesNotReject(sendEvent(event));
    assert.equal(calls.length, 1);
  });

  it("resolves when the URL is malformed", async () => {
    (globalThis as any).fetch = () => {
      throw new TypeError("Invalid URL");
    };
    setEnv({
      ANALYTICS_ENDPOINT_URL: "not a url",
      ANALYTICS_API_KEY: "secret-key",
    });

    await assert.doesNotReject(sendEvent(event));
  });

  it("resolves when fetch never settles", async () => {
    const timeout = mock.method(AbortSignal, "timeout", () => AbortSignal.abort());
    fetchImpl = (_url, init) =>
      new Promise((_resolve, reject) => {
        const signal = init.signal!;
        if (signal.aborted) return reject(signal.reason);
        signal.addEventListener("abort", () => reject(signal.reason));
      });

    await assert.doesNotReject(sendEvent(event));
    assert.equal(timeout.mock.callCount(), 1);
    assert.equal(typeof timeout.mock.calls[0].arguments[0], "number");
    assert.ok(calls[0].init.signal);
  });
});
