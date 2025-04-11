export function compareVersions(a, b) {
  const aParts = a.split(".").map(Number);
  const bParts = b.split(".").map(Number);
  const maxLength = Math.max(aParts.length, bParts.length);

  for (let i = 0; i < maxLength; i++) {
    const aVal = aParts[i] === undefined ? 0 : aParts[i];
    const bVal = bParts[i] === undefined ? 0 : bParts[i];

    if (aVal < bVal) {
      return -1;
    }
    if (aVal > bVal) {
      return 1;
    }
  }

  return 0;
}
