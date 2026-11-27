export type AnalyticsEvent = {
  x_edge_request_id: string;
  logged_at_utc: string;
  x_host_header: string;
  cs_uri_stem: string;
  sc_status: number;
  cs_user_agent: string;
  c_ip: string;
  cs_method: string;
  cs_referer_domain: string;
  cs_uri_query_utm_ktm: string;
  sc_content_type: string;
};

const TIMEOUT_MS = 2000;

export const sendEvent = async (event: AnalyticsEvent): Promise<void> => {
  try {
    const url = Netlify.env.get("ANALYTICS_ENDPOINT_URL");
    const key = Netlify.env.get("ANALYTICS_API_KEY");
    if (!url || !key) return;

    await fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": key },
      body: JSON.stringify(event),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    }).catch(() => {});
  } catch {
    // analytics must never affect the served page
  }
};
