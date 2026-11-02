// Segment events for the arcade. Segment and the consent helper are only on
// production pages (see _layouts/default.html), so every call is a no-op
// when either is missing or blocked.
export function track(event, properties = {}) {
  if (import.meta.env.DEV) console.debug("[arcade]", event, properties);
  window.analytics?.track?.(event, properties, window.getSegmentConsentContext?.() ?? {});
}
