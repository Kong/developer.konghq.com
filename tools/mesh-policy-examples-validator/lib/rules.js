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
