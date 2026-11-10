import test from 'node:test';
import assert from 'node:assert/strict';
import { syncReleases } from '../../lib/tool-versions.js';

const dataFile = 'app/_data/tools/kongctl.yml';

function fakeFetch(releases, { ok = true, status = 200, statusText = 'OK' } = {}) {
  const calls = [];
  const fetchImpl = async (url, options = {}) => {
    calls.push({ url, options });
    return { ok, status, statusText, json: async () => releases };
  };
  return { fetchImpl, calls };
}

function fakeWriter() {
  const writes = [];
  return { writeFile: (filePath, content) => writes.push({ filePath, content }), writes };
}

test('fetches releases from the public Kong/kongctl repo', async () => {
  const { fetchImpl, calls } = fakeFetch([]);
  const { writeFile } = fakeWriter();

  await syncReleases({ repo: 'Kong/kongctl', dataFile, name: 'kongctl', fetch: fetchImpl, writeFile });

  assert.equal(calls[0].url, 'https://api.github.com/repos/Kong/kongctl/releases');
});

test('a failed request suggests GH_TOKEN for rate limits without calling the public repo internal', async () => {
  const { fetchImpl } = fakeFetch([], { ok: false, status: 403, statusText: 'Forbidden' });
  const { writeFile, writes } = fakeWriter();

  await assert.rejects(
    syncReleases({ repo: 'Kong/kongctl', dataFile, name: 'kongctl', fetch: fetchImpl, writeFile, env: {} }),
    (error) =>
      /Kong\/kongctl/.test(error.message) &&
      /GH_TOKEN/.test(error.message) &&
      !/internal repository/.test(error.message),
  );
  assert.equal(writes.length, 0);
});

test('keeps at most the 10 newest series, marking only the newest latest', async () => {
  const releases = Array.from({ length: 12 }, (_, i) => ({
    tag_name: `v1.${30 - i}.0`,
    published_at: `2026-${String(12 - i).padStart(2, '0')}-01T10:00:00Z`,
    draft: false,
    prerelease: false,
  }));
  const { fetchImpl } = fakeFetch(releases);
  const { writeFile, writes } = fakeWriter();

  const series = await syncReleases({ repo: 'Kong/kongctl', dataFile, name: 'kongctl', fetch: fetchImpl, writeFile });

  const releaseLines = writes[0].content.split('\n').filter((line) => line.trim().startsWith('- release:'));
  assert.equal(releaseLines.length, 10);
  assert.equal(series.length, 10);
  assert.equal(series.filter((row) => row.latest).length, 1);
  assert.equal(series[0].latest, true);
  assert.equal(series[0].version, '1.30.0');
});
