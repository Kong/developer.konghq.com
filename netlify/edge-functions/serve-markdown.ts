import type { Config, Context} from "@netlify/edge-functions";

export default async (request: Request, context: Context) => {
  const acceptHeader = request.headers.get("Accept") || "";

  if (!acceptHeader.includes("text/markdown")) {
    return;
  }

  const url = new URL(request.url);

  if (url.pathname === "/") {
    url.pathname = "/index.md";
    return context.rewrite(url);
  }

  const mdPath = url.pathname.replace(/\/?$/, ".md").replace(/\.html\.md$/, ".md");
  url.pathname = mdPath;

  return context.rewrite(url);
};

export const config: Config = {
  path: "/*",
  excludedPath: [
    "/*.css", "/*.js", "/*.png", "/*.jpg", "/*.jpeg",
    "/*.gif", "/*.svg", "/*.ico", "/*.webp",
    "/*.woff", "/*.woff2", "/*.ttf", "/*.eot",
    "/*.json", "/*.xml", "/*.map",
  ],
  onError: "bypass",
};
