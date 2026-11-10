import test from 'node:test';
import assert from 'node:assert/strict';
import { syncReleases } from '../../lib/tool-versions.js';

const dataFile = 'app/_data/tools/kong-harnesses.yml';

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

test('groups releases by major.minor series, keeping the highest patch and marking only the newest series latest', async () => {
  const { fetchImpl } = fakeFetch([
    { tag_name: 'v0.4.1', published_at: '2026-10-01T10:00:00Z', draft: false, prerelease: false },
    { tag_name: 'v0.4.0', published_at: '2026-09-20T10:00:00Z', draft: false, prerelease: false },
    { tag_name: 'v0.3.2', published_at: '2026-08-15T10:00:00Z', draft: false, prerelease: false },
    { tag_name: 'v0.5.0', published_at: '2026-10-02T10:00:00Z', draft: true, prerelease: false },
    { tag_name: 'v0.3.3-rc1', published_at: '2026-09-01T10:00:00Z', draft: false, prerelease: true },
  ]);
  const { writeFile, writes } = fakeWriter();

  await syncReleases({ repo: 'Kong/kong-harnesses', dataFile, name: 'kong-harnesses', fetch: fetchImpl, writeFile });

  assert.deepEqual(
    writes.map((w) => w.content),
    [
      'name: kong-harnesses\n\nreleases:\n' +
        '  - release: "0.4"\n' +
        '    version: "0.4.1"\n' +
        '    latest: true\n' +
        '    released: 2026-10-01\n' +
        '  - release: "0.3"\n' +
        '    version: "0.3.2"\n' +
        '    released: 2026-08-15\n',
    ],
  );
  assert.equal(writes[0].filePath, dataFile);
});

test('fetches releases from the GitHub API for the configured repo', async () => {
  const { fetchImpl, calls } = fakeFetch([]);
  const { writeFile } = fakeWriter();

  await syncReleases({ repo: 'Kong/kong-harnesses', dataFile, name: 'kong-harnesses', fetch: fetchImpl, writeFile });

  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, 'https://api.github.com/repos/Kong/kong-harnesses/releases');
});

test('sends an Authorization Bearer header built from GH_TOKEN when it is set', async () => {
  const { fetchImpl, calls } = fakeFetch([]);
  const { writeFile } = fakeWriter();

  await syncReleases({
    repo: 'Kong/kong-harnesses',
    dataFile,
    name: 'kong-harnesses',
    fetch: fetchImpl,
    writeFile,
    env: { GH_TOKEN: 'ghp_test-token' },
  });

  assert.equal(calls[0].options.headers.Authorization, 'Bearer ghp_test-token');
});

test('sends no Authorization header when GH_TOKEN is not set', async () => {
  const { fetchImpl, calls } = fakeFetch([]);
  const { writeFile } = fakeWriter();

  await syncReleases({ repo: 'Kong/kong-harnesses', dataFile, name: 'kong-harnesses', fetch: fetchImpl, writeFile, env: {} });

  assert.equal(calls[0].options.headers.Authorization, undefined);
});

test('throws an error naming the token requirement when the request fails', async () => {
  const { fetchImpl } = fakeFetch([], { ok: false, status: 404, statusText: 'Not Found' });
  const { writeFile, writes } = fakeWriter();

  await assert.rejects(
    syncReleases({
      repo: 'Kong/kong-harnesses',
      dataFile,
      name: 'kong-harnesses',
      internalRepo: true,
      fetch: fetchImpl,
      writeFile,
      env: {},
    }),
    (error) =>
      /GH_TOKEN/.test(error.message) && /internal repository/.test(error.message),
  );
  assert.equal(writes.length, 0);
});

test('accepts releases tagged without a leading v', async () => {
  const { fetchImpl } = fakeFetch([
    { tag_name: '0.5.2', published_at: '2026-10-05T12:00:00Z', draft: false, prerelease: false },
    { tag_name: '0.5.10', published_at: '2026-10-06T12:00:00Z', draft: false, prerelease: false },
    { tag_name: '0.5.9', published_at: '2026-10-05T18:00:00Z', draft: false, prerelease: false },
  ]);
  const { writeFile, writes } = fakeWriter();

  await syncReleases({ repo: 'Kong/kong-harnesses', dataFile, name: 'kong-harnesses', fetch: fetchImpl, writeFile });

  assert.equal(
    writes[0].content,
    'name: kong-harnesses\n\nreleases:\n' +
      '  - release: "0.5"\n' +
      '    version: "0.5.10"\n' +
      '    latest: true\n' +
      '    released: 2026-10-06\n',
  );
});

test('derives the released date from published_at', async () => {
  const { fetchImpl } = fakeFetch([
    { tag_name: 'v0.4.1', published_at: '2026-10-01T10:15:30Z', draft: false, prerelease: false },
  ]);
  const { writeFile, writes } = fakeWriter();

  await syncReleases({ repo: 'Kong/kong-harnesses', dataFile, name: 'kong-harnesses', fetch: fetchImpl, writeFile });

  assert.equal(writes[0].content, 'name: kong-harnesses\n\nreleases:\n  - release: "0.4"\n    version: "0.4.1"\n    latest: true\n    released: 2026-10-01\n');
});

test('consumes whatever the API returned without paginating', async () => {
  const releases = [1, 2, 3, 4, 5, 6].map((minor) => ({
    tag_name: `v0.${minor}.0`,
    published_at: `2026-09-0${minor}T10:00:00Z`,
    draft: false,
    prerelease: false,
  }));
  const { fetchImpl, calls } = fakeFetch(releases);
  const { writeFile, writes } = fakeWriter();

  await syncReleases({ repo: 'Kong/kong-harnesses', dataFile, name: 'kong-harnesses', fetch: fetchImpl, writeFile });

  assert.equal(calls.length, 1);
  assert.ok(!calls[0].url.includes('?'), 'the sync must not request further pages');
  const releaseLines = writes[0].content.split('\n').filter((line) => line.trim().startsWith('- release:'));
  assert.equal(releaseLines.length, releases.length);
});
