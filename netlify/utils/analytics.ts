export type AnalyticsEvent = {
  path: string;
  format: "html" | "markdown";
  user_agent: string;
  timestamp: string;
};

const TIMEOUT_MS = 2000;

export const sendEvent = async (event: AnalyticsEvent): Promise<void> => {
  try {
    const url = Netlify.env.get("ANALYTICS_ENDPOINT_URL");
    const key = Netlify.env.get("ANALYTICS_API_KEY");
    if (!url || !key) return;

    const { path, format, user_agent, timestamp } = event;
    await fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": key },
      body: JSON.stringify({ path, format, user_agent, timestamp }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    }).catch(() => {});
  } catch {
    // analytics must never affect the served page
  }
};
