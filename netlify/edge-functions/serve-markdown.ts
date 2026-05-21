import type { Config, Context } from "@netlify/edge-functions";

export default async (request: Request, context: Context) => {
  const acceptHeader = request.headers.get("Accept") || "";
  const url = new URL(request.url);
  const { pathname } = url;

  let nextRequest: Request = request;
  if (acceptHeader.includes("text/markdown") && !pathname.endsWith(".md")) {
    url.pathname =
      pathname === "/"
        ? "/index.md"
        : pathname.replace(/\/?$/, ".md").replace(/\.html\.md$/, ".md");
    nextRequest = new Request(url, request);
  }

  const response = await context.next(nextRequest);

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
          status_code: response.status,
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
    "/assets/*",
    "/vite/assets/*",
    "/**/*.css", "/**/*.js", "/**/*.png", "/**/*.jpg", "/**/*.jpeg",
    "/**/*.gif", "/**/*.svg", "/**/*.ico", "/**/*.webp",
    "/**/*.woff", "/**/*.woff2", "/**/*.ttf", "/**/*.eot",
    "/**/*.json", "/**/*.xml", "/**/*.map"
  ],
  onError: "bypass",
};
