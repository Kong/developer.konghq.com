function parseTarget(value) {
  let url;
  try {
    url = new URL(value);
  } catch {
    throw new Error(
      `"${value}" is not an absolute URL. Set BASE_URL (or baseUrl in config/tests.yaml) to an http(s) URL.`,
    );
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error(
      `"${value}" is not an absolute URL. Set BASE_URL (or baseUrl in config/tests.yaml) to an http(s) URL.`,
    );
  }

  return url;
}

export function resolveDevServerTarget(rawConfig, env = process.env) {
  const selected = String(env.BASE_URL || rawConfig.baseUrl).trim();
  const url = parseTarget(selected);

  return {
    ...rawConfig,
    baseUrl: selected.replace(/\/+$/, ""),
    origin: url.origin,
  };
}

export function visitedOrigins(urls) {
  const origins = [];
  for (const url of urls) {
    const origin = parseTarget(url).origin;
    if (!origins.includes(origin)) {
      origins.push(origin);
    }
  }
  return origins;
}
