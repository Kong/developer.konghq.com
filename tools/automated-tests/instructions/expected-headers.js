// Assertion checks for the `expected_headers` option of the request blocks
// ({% validation request-check %}, {% konnect_api_request %},
// {% control_plane_request %}, {% validation rate-limit-check %}).
//

/**
 * Build one check function per expected_headers entry.
 *
 * @param {string[] | undefined | null} expectedHeaders entries from the
 *   validation config
 * @param {string} context label for the failure message, e.g.
 *   "request to /echo" or "request 6"
 * @returns {Array<(response: {headers: Headers}) => {assert: boolean, message: string}>}
 */
export function expectedHeaderChecks(expectedHeaders, context) {
  if (!expectedHeaders) {
    return [];
  }

  return expectedHeaders.map((entry) => {
    const separator = entry.indexOf(":");
    const name =
      separator === -1 ? entry.trim() : entry.slice(0, separator).trim();
    const value =
      separator === -1 ? null : entry.slice(separator + 1).trim();

    return (response) => {
      const actual = response.headers.get(name);
      const present = actual !== null && actual !== undefined;
      const matched = value === null ? present : actual === value;
      return {
        assert: matched,
        message: `Expected: ${context} to have header '${entry}', got: '${actual}'.`,
      };
    };
  });
}
