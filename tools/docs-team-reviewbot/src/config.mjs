// Central limits and path rules. Values mirror rubric.md (v0.3).

export const MODEL = process.env.REVIEWBOT_MODEL || "claude-sonnet-5-5";
export const EFFORT = process.env.REVIEWBOT_EFFORT || "medium";

export const LIMITS = {
  maxFindings: 8,
  maxSoftAndOptional: 3,
  maxHumanOnly: 1,
  minConfidence: 0.8,
  maxToolTurns: 30,
  maxDiffChars: 120_000,
  maxToolResultChars: 20_000,
  maxOutputTokens: 16_000,
};

// Only these paths are reviewed.
export const REVIEWABLE = [
  /^app\/.+\.md$/,
  /^app\/_landing_pages\/.+\.ya?ml$/,
  /^app\/_kong_plugins\/[^/]+\/examples\/.+\.ya?ml$/,
];

// Never reviewed: generated content, out-of-scope content, assets.
export const NEVER_REVIEW = [
  /^app\/_references\//,
  /^app\/_changelogs\//,
  /^app\/_kong_plugins\/[^/]+\/changelog\.json$/,
  /^app\/_kong_plugins\/[^/]+\/schema\.json$/,
  /^app\/_schemas\/gateway\/plugins\//,
  /^app\/_includes\/deck\/help\//,
  /^app\/_includes\/kongctl\/help\//,
  /^app\/_api\//,
  /^api-specs\//,
  /^app\/_support\//, // support articles use the review-support-article skill
  /^app\/assets\//,
  /^app\/\.repos\//,
];

export function isReviewable(path) {
  return REVIEWABLE.some((r) => r.test(path)) && !NEVER_REVIEW.some((r) => r.test(path));
}

export const TIER_ORDER = ["always_flag", "flag_softly", "human_only", "optional"];
export const SEVERITY_ORDER = ["blocking", "should_fix", "optional"];
