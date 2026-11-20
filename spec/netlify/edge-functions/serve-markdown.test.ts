import { afterEach, beforeEach, describe, it, mock } from "node:test";
import assert from "node:assert/strict";

import handler, { config } from "../../../netlify/edge-functions/serve-markdown.ts";

const ORIGIN = "https://developer.konghq.com";

type NextCall = unknown[];

const setup = (nextResponse: Response = new Response("page", { status: 200 })) => {
  const waited: Promise<unknown>[] = [];
  const nextCalls: NextCall[] = [];
  const context: Record<string, any> = {
    ip: "203.0.113.42",
    requestId: "req-123",
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
  let events: Record<string, any>[];

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
    mock.timers.reset();
    delete (globalThis as any).Netlify;
  });

  const run = async (
    path: string,
    {
      method = "GET",
      accept,
      userAgent = "test-agent",
      headers: extraHeaders = {},
    }: { method?: string; accept?: string; userAgent?: string; headers?: Record<string, string> } = {},
    nextResponse?: Response,
  ) => {
    const { context, waited, nextCalls, nextResponse: expected } = setup(nextResponse);
    const headers: Record<string, string> = { "user-agent": userAgent, ...extraHeaders };
    if (accept) headers.accept = accept;
    const request = new Request(path.startsWith("http") ? path : `${ORIGIN}${path}`, { method, headers });
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
    assert.equal(events[0].cs_uri_stem, "/kongctl/");
    assert.equal(events[0].sc_status, 200);
    assert.equal(events[0].cs_user_agent, "test-agent");
    assert.equal(events[0].c_ip, "203.0.113.42");
  });

  it("sends exactly the log field set", async () => {
    await run("/kongctl/");

    assert.deepEqual(Object.keys(events[0]).sort(), [
      "c_ip",
      "cs_method",
      "cs_referer_domain",
      "cs_uri_query_utm_ktm",
      "cs_uri_stem",
      "cs_user_agent",
      "logged_at_utc",
      "sc_content_type",
      "sc_status",
      "x_edge_request_id",
      "x_host_header",
    ]);
  });

  it("sends the platform request id", async () => {
    await run("/kongctl/");

    assert.equal(events[0].x_edge_request_id, "req-123");
  });

  it("sends the time at handler start, to the second, in UTC", async () => {
    mock.timers.enable({ apis: ["Date"], now: Date.parse("2026-11-20T14:03:12.345Z") });
    const { context, waited } = setup();
    context.next = async () => {
      mock.timers.tick(5000);
      return new Response("page", { status: 200 });
    };

    await (handler as any)(new Request(`${ORIGIN}/kongctl/`), context);
    await Promise.all(waited);

    assert.match(events[0].logged_at_utc, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
    assert.equal(events[0].logged_at_utc, "2026-11-20T14:03:12Z");
  });

  it("sends the hostname without a port", async () => {
    await run("http://localhost:8938/kongctl/");

    assert.equal(events[0].x_host_header, "localhost");
  });

  it("sends the method", async () => {
    await run("/kongctl/");

    assert.equal(events[0].cs_method, "GET");
  });

  it("sends a long User-Agent unchanged", async () => {
    const userAgent = `Mozilla/5.0 ${"x".repeat(588)}`;

    await run("/kongctl/", { userAgent });

    assert.equal(userAgent.length, 600);
    assert.equal(events[0].cs_user_agent, userAgent);
  });

  it("sends the lowercase referrer hostname without port or path", async () => {
    await run("/kongctl/", { headers: { referer: "https://www.Google.com:443/search?q=kong" } });

    assert.equal(events[0].cs_referer_domain, "www.google.com");
  });

  it("sends an empty referrer domain when the header is missing", async () => {
    await run("/kongctl/");

    assert.equal(events[0].cs_referer_domain, "");
  });

  it("sends an empty referrer domain when the header is not a URL", async () => {
    await run("/kongctl/", { headers: { referer: "not a url" } });

    assert.equal(events[0].cs_referer_domain, "");
  });

  it("keeps only utm_ and ktm_ parameters, in order and as encoded", async () => {
    await run("/kongctl/?foo=1&utm_source=x&ktm_id=y&UTM_x=z");

    assert.equal(events[0].cs_uri_query_utm_ktm, "utm_source=x&ktm_id=y");
  });

  it("keeps percent-encoding in the query field", async () => {
    await run("/kongctl/?utm_term=a%20b&ktm_id=y%2Fz");

    assert.equal(events[0].cs_uri_query_utm_ktm, "utm_term=a%20b&ktm_id=y%2Fz");
  });

  it("keeps the marker out of the query field", async () => {
    await run("/kongctl.md?utm_source=x&_md_rewrite=1", { accept: "text/markdown" });

    assert.equal(events[0].cs_uri_query_utm_ktm, "utm_source=x");
  });

  it("sends an empty query field when there is no query", async () => {
    await run("/kongctl/");

    assert.equal(events[0].cs_uri_query_utm_ktm, "");
  });

  it("sends the content type of the next response", async () => {
    await run("/kongctl/", {}, new Response("page", { headers: { "content-type": "text/html; charset=utf-8" } }));

    assert.equal(events[0].sc_content_type, "text/html; charset=utf-8");
  });

  it("sends an empty content type when the next response has none", async () => {
    const response = new Response(null, { status: 304 });

    await run("/kongctl/", {}, response);

    assert.equal(response.headers.get("content-type"), null);
    assert.equal(events[0].sc_content_type, "");
  });

  it("sends an empty ip when the platform gives none", async () => {
    const { context, waited } = setup();
    context.ip = undefined;
    const request = new Request(`${ORIGIN}/kongctl/`, { headers: { "user-agent": "test-agent" } });

    await (handler as any)(request, context);
    await Promise.all(waited);

    assert.equal(events.length, 1);
    assert.equal(events[0].c_ip, "");
  });

  it("rewrites an Accept markdown request with the marker and sends no event in run 1", async () => {
    const { result, nextCalls } = await run("/kongctl/", { accept: "text/markdown" });

    assert.ok(result instanceof URL);
    assert.equal(result.pathname, "/kongctl.md");
    assert.equal(result.search, "?_md_rewrite=1");
    assert.equal(nextCalls.length, 0);
    assert.equal(events.length, 0);
  });

  it("keeps the visitor query in the rewrite URL and appends the marker", async () => {
    const { result } = await run("/kongctl/?utm_source=x&foo=1", { accept: "text/markdown" });

    assert.ok(result instanceof URL);
    assert.equal(result.pathname, "/kongctl.md");
    assert.equal(result.search, "?utm_source=x&foo=1&_md_rewrite=1");
  });

  it("rewrites / to /index.md with the marker and no event", async () => {
    const { result, nextCalls } = await run("/", { accept: "text/markdown" });

    assert.ok(result instanceof URL);
    assert.equal(result.pathname, "/index.md");
    assert.equal(result.search, "?_md_rewrite=1");
    assert.equal(nextCalls.length, 0);
    assert.equal(events.length, 0);
  });

  it("logs the page path for a marked rewrite (run 2)", async () => {
    const { nextCalls, result, expected } = await run("/kongctl.md?_md_rewrite=1", { accept: "text/markdown" });

    assert.equal(nextCalls.length, 1);
    assert.equal(result, expected);
    assert.equal(events.length, 1);
    assert.equal(events[0].cs_uri_stem, "/kongctl/");
    assert.equal(events[0].sc_status, 200);
  });

  it("logs /index.md?_md_rewrite=1 as /", async () => {
    await run("/index.md?_md_rewrite=1", { accept: "text/markdown" });

    assert.equal(events.length, 1);
    assert.equal(events[0].cs_uri_stem, "/");
  });

  for (const accept of [undefined, "text/markdown"]) {
    it(`logs the raw path for a direct /kongctl.md request (Accept: ${accept ?? "none"})`, async () => {
      const { result, nextCalls, expected } = await run("/kongctl.md", { accept });

      assert.equal(nextCalls.length, 1);
      assert.equal(result, expected);
      assert.equal(events.length, 1);
      assert.equal(events[0].cs_uri_stem, "/kongctl.md");
      assert.equal(events[0].sc_status, 200);
    });

    it(`logs the raw path for a direct /index.md request (Accept: ${accept ?? "none"})`, async () => {
      await run("/index.md", { accept });

      assert.equal(events.length, 1);
      assert.equal(events[0].cs_uri_stem, "/index.md");
    });
  }

  it("sends the status of the next response for a marked rewrite (run 2)", async () => {
    await run("/kongctl.md?_md_rewrite=1", { accept: "text/markdown" }, new Response("moved", { status: 301 }));

    assert.equal(events.length, 1);
    assert.equal(events[0].sc_status, 301);
  });

  it("counts /llms.txt", async () => {
    const { nextCalls } = await run("/llms.txt");

    assert.equal(nextCalls.length, 1);
    assert.equal(events.length, 1);
    assert.equal(events[0].cs_uri_stem, "/llms.txt");
  });

  it("serves /llms.txt unchanged when the client accepts markdown", async () => {
    const { result, nextCalls, expected } = await run("/llms.txt", { accept: "text/markdown" });

    assert.ok(!(result instanceof URL));
    assert.equal(result, expected);
    assert.equal(nextCalls.length, 1);
    assert.equal(events.length, 1);
    assert.equal(events[0].cs_uri_stem, "/llms.txt");
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
    assert.equal(events[0].sc_status, 304);
  });

  it("sends status 404 for a missing page", async () => {
    const { result } = await run("/this-page-does-not-exist/", {}, new Response("missing", { status: 404 }));

    assert.equal((result as Response).status, 404);
    assert.equal(events.length, 1);
    assert.equal(events[0].sc_status, 404);
  });

  it("rejects with the same error and sends no event when next throws", async () => {
    const { context, waited } = setup();
    const failure = new Error("origin failed");
    context.next = async () => {
      throw failure;
    };
    const request = new Request(`${ORIGIN}/kongctl/`, { headers: { "user-agent": "test-agent" } });

    await assert.rejects((handler as any)(request, context), failure);
    await Promise.all(waited);

    assert.equal(waited.length, 0);
    assert.equal(events.length, 0);
  });

  describe("redirect Location", () => {
    const redirect = (location: string) =>
      new Response("moved", {
        status: 301,
        headers: { location, "cache-control": "public, max-age=0", "x-custom": "kept" },
      });

    it("removes the marker from the Location of a marked redirect and keeps the other parameters", async () => {
      const { result, expected } = await run(
        "/kongctl/create/foo.md?utm_source=x&_md_rewrite=1",
        { accept: "text/markdown" },
        redirect("/kongctl/?utm_source=x&_md_rewrite=1"),
      );

      assert.notEqual(result, expected);
      assert.equal(result.status, 301);
      assert.equal(result.headers.get("location"), "/kongctl/?utm_source=x");
      assert.equal(result.headers.get("cache-control"), "public, max-age=0");
      assert.equal(result.headers.get("x-custom"), "kept");
      assert.equal(await result.text(), "moved");
    });

    it("removes the whole query when the marker is the only parameter", async () => {
      const { result } = await run(
        "/kongctl/create/foo.md?_md_rewrite=1",
        { accept: "text/markdown" },
        redirect("/kongctl/?_md_rewrite=1"),
      );

      assert.equal(result.headers.get("location"), "/kongctl/");
    });

    it("counts the marked redirect with its own status", async () => {
      await run(
        "/kongctl/create/foo.md?utm_source=x&_md_rewrite=1",
        { accept: "text/markdown" },
        redirect("/kongctl/?utm_source=x&_md_rewrite=1"),
      );

      assert.equal(events.length, 1);
      assert.equal(events[0].sc_status, 301);
    });

    it("returns the next response itself when the request has no marker", async () => {
      const { result, expected } = await run(
        "/kongctl/create/foo.md",
        { accept: "text/markdown" },
        redirect("/kongctl/?_md_rewrite=1"),
      );

      assert.strictEqual(result, expected);
    });

    for (const status of [200, 304]) {
      it(`returns the next response itself for a marked ${status}`, async () => {
        const { result, expected } = await run(
          "/kongctl.md?_md_rewrite=1",
          { accept: "text/markdown" },
          new Response(status === 304 ? null : "page", { status }),
        );

        assert.strictEqual(result, expected);
      });
    }
  });
});

describe("serve-markdown config", () => {
  const excluded = config.excludedPath as string[];

  it("excludes asset directories and machine files", () => {
    for (const pattern of ["/assets/*", "/vite/assets/*", "/robots.txt", "/**/*.xml"]) {
      assert.ok(excluded.includes(pattern), `${pattern} is excluded`);
    }
  });

  it("excludes the static file types published outside /assets/", () => {
    for (const pattern of ["/**/*.yaml", "/**/*.yml", "/**/*.sh", "/**/*.ps1"]) {
      assert.ok(excluded.includes(pattern), `${pattern} is excluded`);
    }
  });

  it("does not exclude all .txt files, so /llms.txt runs the function", () => {
    assert.ok(!excluded.includes("/**/*.txt"));
  });

  it("runs the function for counted paths and skips the excluded static files", () => {
    const patterns = excluded.map((pattern) => new URLPattern({ pathname: pattern }));
    const runs = (path: string) => !patterns.some((pattern) => pattern.test({ pathname: path }));

    for (const path of ["/kongctl/", "/kongctl.md", "/llms.txt", "/index.md", "/"]) {
      assert.ok(runs(path), `${path} is counted`);
    }

    for (const path of [
      "/logo.css",
      "/entrypoints/app.js",
      "/images/icon.png",
      "/images/icon.svg",
      "/fonts/font.woff",
      "/vite/assets/index.json",
      "/manifests/kic/echo-service.yaml",
      "/insomnia/Flights-Service-0.1.0.yaml",
      "/mesh/installer.sh",
      "/mesh/installer.ps1",
      "/robots.txt",
      "/sitemap.xml",
      "/feeds/security-advisories.xml",
    ]) {
      assert.ok(!runs(path), `${path} is excluded`);
    }
  });
});
