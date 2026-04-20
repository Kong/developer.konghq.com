import type { Config } from "@netlify/edge-functions";

export default async (request: Request) => {
  const acceptHeader = request.headers.get("Accept") || "";

  if (!acceptHeader.includes("text/markdown")) {
    return;
  }

  const url = new URL(request.url);
  const { pathname } = url;

  if (pathname.endsWith(".md")) {
    return;
  }

  if (pathname === "/") {
    url.pathname = `${pathname}index.md`;
  } else {
    url.pathname = pathname.replace(/\.html$/, "") + ".md";
  }

  return url;
};

export const config: Config = {
  path: "/*",
  excludedPath: [
    "/**/*.css", "/**/*.js", "/**/*.png", "/**/*.jpg", "/**/*.jpeg",
    "/**/*.gif", "/**/*.svg", "/**/*.ico", "/**/*.webp",
    "/**/*.woff", "/**/*.woff2", "/**/*.ttf", "/**/*.eot",
    "/**/*.json", "/**/*.xml", "/**/*.map",
  ],
  onError: "bypass",
};
