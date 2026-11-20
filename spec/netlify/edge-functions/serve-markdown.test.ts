import { afterEach, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";

import handler, { config } from "../../../netlify/edge-functions/serve-markdown.ts";

const ORIGIN = "https://developer.konghq.com";

type NextCall = unknown[];

const setup = (nextResponse: Response = new Response("page", { status: 200 })) => {
  const waited: Promise<unknown>[] = [];
  const nextCalls: NextCall[] = [];
  const context = {
    waitUntil: (promise: Promise<unknown>) => {
      waited.push(promise);
    },
    next: async (...args: unknown[]) => {
      nextCalls.push(args);
      return nextResponse;
    },
  };
  return { context, waited, nextCalls, nextResponse };
};

describe("serve-markdown handler", () => {
  let events: Record<string, string>[];

  beforeEach(() => {
    events = [];
    (globalThis as any).Netlify = {
      env: {
        get: (key: string) =>
          ({
            ANALYTICS_ENDPOINT_URL: "https://analytics.example.test/events",
            ANALYTICS_API_KEY: "secret-key",
          })[key],
      },
    };
    (globalThis as any).fetch = async (_url: string, init: RequestInit) => {
      events.push(JSON.parse(init.body as string));
      return new Response(null, { status: 204 });
    };
  });

  afterEach(() => {
    delete (globalThis as any).Netlify;
  });

  const run = async (
    path: string,
    { method = "GET", accept, userAgent = "test-agent" }: { method?: string; accept?: string; userAgent?: string } = {},
    nextResponse?: Response,
  ) => {
    const { context, waited, nextCalls, nextResponse: expected } = setup(nextResponse);
    const headers: Record<string, string> = { "user-agent": userAgent };
    if (accept) headers.accept = accept;
    const request = new Request(`${ORIGIN}${path}`, { method, headers });
    const result = await (handler as any)(request, context);
    await Promise.all(waited);
    return { result, nextCalls, expected };
  };

  it("counts an HTML request once and passes the response through", async () => {
    const { result, nextCalls, expected } = await run("/kongctl/");

    assert.equal(nextCalls.length, 1);
    assert.deepEqual(nextCalls[0], [{ sendConditionalRequest: true }]);
    assert.equal(result, expected);
    assert.equal(events.length, 1);
    assert.equal(events[0].format, "html");
    assert.equal(events[0].path, "/kongctl/");
    assert.equal(events[0].user_agent, "test-agent");
    assert.ok(!Number.isNaN(Date.parse(events[0].timestamp)));
  });

  it("rewrites an Accept markdown request and sends no event in run 1", async () => {
    const { result, nextCalls } = await run("/kongctl/", { accept: "text/markdown" });

    assert.ok(result instanceof URL);
    assert.equal(result.pathname, "/kongctl.md");
    assert.equal(nextCalls.length, 0);
    assert.equal(events.length, 0);
  });

  for (const accept of [undefined, "text/markdown"]) {
    it(`counts /kongctl.md once as markdown on /kongctl/ (Accept: ${accept ?? "none"})`, async () => {
      const { result, nextCalls, expected } = await run("/kongctl.md", { accept });

      assert.equal(nextCalls.length, 1);
      assert.equal(result, expected);
      assert.equal(events.length, 1);
      assert.equal(events[0].format, "markdown");
      assert.equal(events[0].path, "/kongctl/");
    });
  }

  it("rewrites / to /index.md with no event", async () => {
    const { result, nextCalls } = await run("/", { accept: "text/markdown" });

    assert.ok(result instanceof URL);
    assert.equal(result.pathname, "/index.md");
    assert.equal(nextCalls.length, 0);
    assert.equal(events.length, 0);
  });

  it("logs /index.md as /", async () => {
    await run("/index.md", { accept: "text/markdown" });

    assert.equal(events.length, 1);
    assert.equal(events[0].path, "/");
    assert.equal(events[0].format, "markdown");
  });

  it("counts /llms.txt as markdown", async () => {
    const { nextCalls } = await run("/llms.txt");

    assert.equal(nextCalls.length, 1);
    assert.equal(events.length, 1);
    assert.equal(events[0].format, "markdown");
    assert.equal(events[0].path, "/llms.txt");
  });

  for (const method of ["HEAD", "OPTIONS"]) {
    it(`ignores ${method} requests`, async () => {
      const { result, nextCalls } = await run("/kongctl/", { method });

      assert.equal(result, undefined);
      assert.equal(nextCalls.length, 0);
      assert.equal(events.length, 0);
    });
  }

  it("returns the next response when registering the event throws", async () => {
    const { context, nextResponse } = setup();
    context.waitUntil = () => {
      throw new Error("waitUntil failed");
    };
    const request = new Request(`${ORIGIN}/kongctl/`, { headers: { "user-agent": "test-agent" } });

    const result = await (handler as any)(request, context);

    assert.equal(result, nextResponse);
  });

  it("returns a 304 unchanged and counts it", async () => {
    const notModified = new Response(null, { status: 304 });

    const { result } = await run("/kongctl/", {}, notModified);

    assert.equal(result, notModified);
    assert.equal(events.length, 1);
  });
});

describe("serve-markdown config", () => {
  const excluded = config.excludedPath as string[];

  it("excludes asset directories and machine files", () => {
    for (const pattern of ["/assets/*", "/vite/assets/*", "/robots.txt", "/**/*.xml"]) {
      assert.ok(excluded.includes(pattern), `${pattern} is excluded`);
    }
  });

  it("does not exclude all .txt files, so /llms.txt runs the function", () => {
    assert.ok(!excluded.includes("/**/*.txt"));
  });
});
