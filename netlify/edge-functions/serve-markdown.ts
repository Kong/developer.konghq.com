import type { Config, Context } from "@netlify/edge-functions";

export default async (request: Request, context: Context) => {
  const acceptHeader = request.headers.get("Accept") || "";
  const url = new URL(request.url);
  const { pathname } = url;

  let response: URL | undefined;

  if (acceptHeader.includes("text/markdown") && !pathname.endsWith(".md")) {
    if (pathname === "/") {
      url.pathname = "/index.md";
    } else {
      url.pathname = pathname.replace(/\/?$/, ".md").replace(/\.html\.md$/, ".md");
    }
    response = url;
  }

  const apiKey = Netlify.env.get("PROFOUND_API_KEY");
  const loggingEnabled = Netlify.env.get("LOG_TO_PROFOUND") === "true";

  if (apiKey && loggingEnabled) {
    const params: Record<string, string> = {};
    url.searchParams.forEach((value, key) => {
      params[key] = value;
    });

    context.waitUntil(
      fetch("https://artemis.api.tryprofound.com/v1/logs/custom", {
        method: "POST",
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify([{
          timestamp: new Date().toISOString(),
          method: request.method,
          host: request.headers.get("host"),
          path: pathname,
          status_code: 200, // hardcoded, we don't want to add extra overhead
          ip: context.ip,
          user_agent: request.headers.get("user-agent"),
          query_params: params,
          referer: request.headers.get("referer"),
        }]),
      })
    );
  }

  return response;
};

export const config: Config = {
  path: "/*",
  excludedPath: [
    "/**/*.css", "/**/*.js", "/**/*.png", "/**/*.jpg", "/**/*.jpeg",
    "/**/*.gif", "/**/*.svg", "/**/*.ico", "/**/*.webp",
    "/**/*.woff", "/**/*.woff2", "/**/*.ttf", "/**/*.eot",
    "/**/*.json", "/**/*.xml", "/**/*.map"
  ],
  onError: "bypass",
};
