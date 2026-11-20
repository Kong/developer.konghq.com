import type { Config, Context } from "@netlify/edge-functions";
import { sendEvent } from "../utils/analytics.ts";

const pagePath = (pathname: string) => {
  if (pathname.endsWith("/index.md")) {
    return pathname.slice(0, -"index.md".length);
  }
  if (pathname.endsWith(".md")) {
    return `${pathname.replace(/(\.html)?\.md$/, "")}/`;
  }
  return pathname;
};

const isMarkdown = (pathname: string) =>
  pathname.endsWith(".md") || pathname === "/llms.txt";

export default async (request: Request, context: Context) => {
  if (request.method !== "GET") {
    return;
  }

  const url = new URL(request.url);
  const { pathname } = url;
  const acceptHeader = request.headers.get("Accept") || "";

  if (acceptHeader.includes("text/markdown") && !pathname.endsWith(".md")) {
    if (pathname === "/") {
      url.pathname = "/index.md";
    } else {
      url.pathname = pathname.replace(/\/?$/, ".md").replace(/\.html\.md$/, ".md");
    }

    return url;
  }

  try {
    context.waitUntil(
      sendEvent({
        path: pagePath(pathname),
        format: isMarkdown(pathname) ? "markdown" : "html",
        user_agent: request.headers.get("User-Agent") || "",
        timestamp: new Date().toISOString(),
      }),
    );
  } catch {
    // analytics must never affect the served page
  }

  return await context.next({ sendConditionalRequest: true });
};

export const config: Config = {
  path: "/*",
  excludedPath: [
    "/**/*.css", "/**/*.js", "/**/*.png", "/**/*.jpg", "/**/*.jpeg",
    "/**/*.gif", "/**/*.svg", "/**/*.ico", "/**/*.webp",
    "/**/*.woff", "/**/*.woff2", "/**/*.ttf", "/**/*.eot",
    "/**/*.json", "/**/*.xml", "/**/*.map",
    "/robots.txt", "/assets/*", "/vite/assets/*"
  ],
  onError: "bypass",
};
