function escapeSegment(segment) {
  return String(segment).replace(/~/g, "~0").replace(/\//g, "~1");
}

export function findNullValues(value, pointer = "") {
  if (value === null || typeof value !== "object") return [];

  const entries = Array.isArray(value)
    ? value.map((item, index) => [index, item])
    : Object.entries(value);

  const findings = [];
  for (const [key, child] of entries) {
    const childPointer = `${pointer}/${escapeSegment(key)}`;
    if (child === null) {
      findings.push(childPointer);
    } else {
      findings.push(...findNullValues(child, childPointer));
    }
  }
  return findings;
}

const MARKER_NAME_PATTERN = /^_/;
const MARKER_NAMES = new Set(["name_uni", "name_kube"]);

// Returns a JSON pointer for every renderer marker key that survived into the
// published output: keys matching `_*`, plus `name_uni` and `name_kube`.
export function findMarkerFields(value, pointer = "") {
  if (value === null || typeof value !== "object") return [];

  if (Array.isArray(value)) {
    return value.flatMap((item, index) =>
      findMarkerFields(item, `${pointer}/${index}`),
    );
  }

  const findings = [];
  for (const [key, child] of Object.entries(value)) {
    const childPointer = `${pointer}/${escapeSegment(key)}`;
    if (MARKER_NAME_PATTERN.test(key) || MARKER_NAMES.has(key)) {
      findings.push(childPointer);
    }
    findings.push(...findMarkerFields(child, childPointer));
  }
  return findings;
}
