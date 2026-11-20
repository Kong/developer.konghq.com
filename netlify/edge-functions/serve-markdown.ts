import type { Config, Context } from "@netlify/edge-functions";
import { sendEvent, type AnalyticsEvent } from "../utils/analytics.ts";

const pagePath = (pathname: string) => {
  if (pathname.endsWith("/index.md")) {
    return pathname.slice(0, -"index.md".length);
  }
  if (pathname.endsWith(".md")) {
    return `${pathname.replace(/(\.html)?\.md$/, "")}/`;
  }
  return pathname;
};

const REWRITE_MARKER = "_md_rewrite";

const isMarkdown = (pathname: string) =>
  pathname.endsWith(".md") || pathname === "/llms.txt";

const utmKtmQuery = (search: string) =>
  search
    .slice(1)
    .split("&")
    .filter((pair) => /^(utm_|ktm_)/.test(pair))
    .join("&");

const refererDomain = (referer: string | null) => {
  try {
    return referer ? new URL(referer).hostname.toLowerCase() : "";
  } catch {
    return "";
  }
};

const withoutMarker = (location: string) => {
  const [beforeHash, ...hash] = location.split("#");
  const [path, ...query] = beforeHash.split("?");
  const kept = query
    .join("?")
    .split("&")
    .filter((pair) => pair !== "" && pair.split("=")[0] !== REWRITE_MARKER)
    .join("&");
  return `${path}${kept ? `?${kept}` : ""}${hash.length ? `#${hash.join("#")}` : ""}`;
};

const buildEvent = (
  request: Request,
  context: Context,
  response: Response,
  url: URL,
  startedAt: Date,
  rewritten: boolean,
): AnalyticsEvent => ({
  x_edge_request_id: context.requestId || "",
  logged_at_utc: startedAt.toISOString().replace(/\.\d{3}Z$/, "Z"),
  x_host_header: url.hostname,
  cs_uri_stem: rewritten ? pagePath(url.pathname) : url.pathname,
  sc_status: response.status,
  cs_user_agent: request.headers.get("User-Agent") || "",
  c_ip: context.ip || "",
  cs_method: request.method,
  cs_referer_domain: refererDomain(request.headers.get("Referer")),
  cs_uri_query_utm_ktm: utmKtmQuery(url.search),
  sc_content_type: response.headers.get("content-type") || "",
});

export default async (request: Request, context: Context) => {
  const startedAt = new Date();
  const url = new URL(request.url);
  const { pathname } = url;
  const acceptHeader = request.headers.get("Accept") || "";
  const counted = request.method === "GET";

  if (acceptHeader.includes("text/markdown") && !isMarkdown(pathname)) {
    if (pathname === "/") {
      url.pathname = "/index.md";
    } else {
      url.pathname = pathname.replace(/\/?$/, ".md").replace(/\.html\.md$/, ".md");
    }

    if (counted) {
      url.search = url.search ? `${url.search}&${REWRITE_MARKER}=1` : `?${REWRITE_MARKER}=1`;
    }
    return url;
  }

  if (!counted) {
    return;
  }

  const rewritten = url.searchParams.get(REWRITE_MARKER) === "1";
  const response = await context.next({ sendConditionalRequest: true });

  try {
    context.waitUntil(
      sendEvent(buildEvent(request, context, response, url, startedAt, rewritten)),
    );
  } catch {
    // analytics must never affect the served page
  }

  const location = response.headers.get("location");
  if (rewritten && location?.includes(REWRITE_MARKER)) {
    const redirect = new Response(response.body, response);
    redirect.headers.set("location", withoutMarker(location));
    return redirect;
  }

  return response;
};

export const config: Config = {
  path: "/*",
  excludedPath: [
    "/**/*.css", "/**/*.js", "/**/*.png", "/**/*.jpg", "/**/*.jpeg",
    "/**/*.gif", "/**/*.svg", "/**/*.ico", "/**/*.webp",
    "/**/*.woff", "/**/*.woff2", "/**/*.ttf", "/**/*.eot",
    "/**/*.json", "/**/*.xml", "/**/*.map", "/**/*.yaml", "/**/*.yml",
    "/**/*.sh", "/**/*.ps1",
    "/robots.txt", "/assets/*", "/vite/assets/*"
  ],
  onError: "bypass",
};
