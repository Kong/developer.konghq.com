# docs-team-reviewbot

An advisory AI reviewer for docs PRs. It reads the diff, checks claims against the repo, and posts inline comments with exact suggested edits.

**It never approves a PR and never requests changes.** It only posts comments (GitHub review event `COMMENT`), it is not a required check, and its GitHub App has no permission beyond `pull_requests: write`. When nothing meets the bar, it posts nothing.

Contents:

- [How it works](#how-it-works)
- [Setup](#setup)
- [Rollout](#rollout)
- [Read the run logs](#read-the-run-logs)
- [Configuration reference](#configuration-reference)
- [Change the rubric](#change-the-rubric)
- [Turn it off](#turn-it-off)
- [Troubleshooting](#troubleshooting)
- [Trust boundary](#trust-boundary)
- [Develop and test locally](#develop-and-test-locally)
- [Not built yet](#not-built-yet)

## How it works

1. `.github/workflows/docs-team-reviewbot.yml` runs on same-repo, non-draft PRs that touch reviewable docs (`app/**/*.md`, landing page YAML, plugin example YAML). Fork PRs are skipped because they get no secrets. The label `ci:skip:reviewbot` skips a PR.
2. `run.mjs` takes `git diff base...head`, keeps only reviewable files (`src/config.mjs`), and numbers each new-file line for the model. Generated paths and `app/_support/` are never reviewed.
3. `src/review.mjs` runs a tool loop with the Anthropic API. The model can call `read_file`, `grep`, and `list_dir`, limited to `app/`, `docs/`, and `api-specs/`. The tools have no shell, no network, and no secrets in their environment (`src/tools.mjs`).
4. `src/validate.mjs` enforces the rubric in code, so a model slip cannot post a forbidden finding:
   - confidence of at least 0.8
   - comments only on added lines
   - a suggestion for fix-style findings
   - at most 8 findings, 3 soft or optional ones, and 1 `human_only` question, which needs a cited inconsistency

   Invalid findings are dropped and logged with a reason.
5. `src/github.mjs` posts one `COMMENT` review. Each comment carries a hidden marker (rule, fingerprint, commit), so re-runs do not repeat a comment. If the author pushes while the bot runs, it posts nothing.
6. The run log (findings kept and dropped, token usage, `verdict_if_live`) is uploaded as a workflow artifact for 90 days. `verdict_if_live` is logged only and never posted.

The rubric the model follows is `rubric.md`. Vale, the frontmatter validator, and the link checker own mechanical issues, so the bot does not comment on them.

## Setup

You need repo admin access to `Kong/developer.konghq.com` and an Anthropic API key approved for CI. Do these once.

### 1. Create the GitHub App

The bot posts comments as a GitHub App so it has its own identity and a minimal permission set.

1. Go to the Kong organization settings, then **Developer settings**, then **GitHub Apps**, then **New GitHub App**.
2. Set the name to `docs-team-reviewbot`. The name appears on every comment it posts.
3. Set the homepage URL to the repo URL.
4. Clear **Active** under **Webhook**. The bot does not need webhooks.
5. Under **Repository permissions**, set **Pull requests** to **Read and write**. Leave every other permission at **No access**. Do not grant **Contents**, **Issues**, or any admin or merge permission.
6. Under **Where can this GitHub App be installed?**, select **Only on this account**.
7. Click **Create GitHub App**.
8. On the App's settings page, copy the **App ID**.
9. Under **Private keys**, click **Generate a private key**. A `.pem` file downloads. Keep it private.
10. Open **Install App**, install it on the Kong organization, and choose **Only select repositories**, then `developer.konghq.com`.

### 2. Add the secrets and variables

In the repo, go to **Settings**, then **Secrets and variables**, then **Actions**.

| Type | Name | Value |
|---|---|---|
| Secret | `ANTHROPIC_API_KEY` | The API key for CI. |
| Secret | `GH_APP_REVIEWBOT_SECRET` | The full contents of the `.pem` file, including the `BEGIN` and `END` lines. |
| Variable | `GH_APP_REVIEWBOT_ID` | The App ID. |

Do not set `REVIEWBOT_ENABLED` yet. Delete the downloaded `.pem` file from your machine once the secret is saved.

### 3. Merge the workflow

Merge the PR that adds `tools/docs-team-reviewbot/` and `.github/workflows/docs-team-reviewbot.yml`. The workflow does nothing until `REVIEWBOT_ENABLED` is `true`, so merging is safe.

Workflows run from the PR's own merge ref for `pull_request` events, so PRs opened before the merge pick up the workflow after they are updated.

## Rollout

Roll out in three stages. Do not skip the dry run.

### Stage 1: dry run

1. Set the variable `REVIEWBOT_ENABLED` to `true`.
2. Leave `REVIEWBOT_DRY_RUN` unset. Unset means dry run.
3. Open or update a docs PR. The **docs-team-reviewbot** check runs and uploads a run log artifact. Nothing is posted.
4. Read the logs from at least 10 to 15 real PRs (see [Read the run logs](#read-the-run-logs)). Check:
   - Findings on PRs you would approve untouched. The bot should be silent or nearly silent on those.
   - Kept findings are ones a maintainer would stand behind.
   - Dropped findings are dropped for good reasons.
   - Token usage and run time are acceptable. Cost per PR has not been measured yet, so record it here.

### Stage 2: advisory comments

1. Set the variable `REVIEWBOT_DRY_RUN` to `false`.
2. The bot now posts inline comments as `docs-team-reviewbot[bot]`. It still never approves or requests changes.
3. Tell contributors and reviewers what it is. Suggested wording: "docs-team-reviewbot leaves optional suggestions. It is advisory, it never blocks a merge, and you can ignore any comment."
4. Run this stage for a few weeks. Ask reviewers to react 👍 or 👎 on each comment. The reactions are the signal for which rules to keep.

### Stage 3: review the results

Every two to three weeks, look at the comments the bot posted and the reactions. Rules with many 👎 or that are never applied should be narrowed or dropped in `rubric.md`. Do not consider any approval or required-check behavior until you have this data and a fresh evaluation.

## Read the run logs

Each run uploads an artifact named `reviewbot-run-log-pr-<number>` containing `run-log.json`.

```bash
# Find the latest run for a PR's branch and download its log
gh run list --workflow docs-team-reviewbot.yml --branch <branch> --limit 1
gh run download <run-id> --name reviewbot-run-log-pr-<number> --dir /tmp/reviewbot
jq '{outcome, posted, dry_run, tool_calls, turns, usage, model_verdict_if_live, computed_verdict_if_live}' /tmp/reviewbot/run-log.json
jq '.kept[] | {file, line, rule, tier, comment}' /tmp/reviewbot/run-log.json
jq '.dropped[] | {rule: .finding.rule, reason}' /tmp/reviewbot/run-log.json
```

Common `outcome` values:

| Outcome | Meaning |
|---|---|
| `dry run` | Findings were kept, nothing was posted because dry run is on. |
| `posted` | Comments were posted. `posted` has the count. |
| `silent: no findings` | Nothing met the bar. This is the normal result for a clean PR. |
| `skipped: no reviewable files` | The PR touched only paths the bot does not review. |
| `skipped: diff too large` | The numbered diff is over 120,000 characters. |
| `skipped: draft PR` | The PR is a draft. |
| `skipped: head moved during review` | The author pushed while the bot ran. The next run handles it. |
| `no review: refused`, `max_tokens`, `bad_json`, `too_many_turns` | The model did not return a usable review. Nothing is posted. |
| `error: model call failed` | The API call failed. The run log has the error. |

`verdict_if_live` (what the bot would have decided) is for analysis only. It is never posted anywhere.

## Configuration reference

Repo variables and secrets used by the workflow:

| Name | Type | Default | Purpose |
|---|---|---|---|
| `REVIEWBOT_ENABLED` | Variable | unset (off) | Must be `true` for the job to run. |
| `REVIEWBOT_DRY_RUN` | Variable | unset (dry run) | Set to `false` to post comments. Any other value or unset means dry run. |
| `REVIEWBOT_MODEL` | Variable | `claude-sonnet-5-5` | Model ID. |
| `REVIEWBOT_EFFORT` | Variable | `medium` | Effort level: `low`, `medium`, `high`, `xhigh`, or `max`. |
| `ANTHROPIC_API_KEY` | Secret | none | Anthropic API key. |
| `GH_APP_REVIEWBOT_ID` | Variable | none | GitHub App ID. |
| `GH_APP_REVIEWBOT_SECRET` | Secret | none | GitHub App private key (PEM). |

Environment variables read by `run.mjs` (set by the workflow, or by you for a local run):

| Name | Purpose |
|---|---|
| `REPO`, `PR_NUMBER`, `BASE_SHA`, `HEAD_SHA` | Which PR and commits to review. Required. |
| `GITHUB_TOKEN` | Read-only token for PR metadata and existing comments. |
| `POST_TOKEN` | The comment-only App token. Without it, the run is always a dry run. |
| `DRY_RUN` | `false` to allow posting (also needs `POST_TOKEN`). |
| `OUT_DIR` | Where `run-log.json` is written. Defaults to the system temp directory. |
| `REVIEWBOT_FALLBACKS` | Set to `off` to disable the server-side refusal fallback. |
| `REVIEWBOT_STRICT` | Set to `true` to make the process exit non-zero on failure. By default failures only warn, so the bot never fails a PR. |

Limits (diff size, finding caps, confidence floor, tool turns) are in `src/config.mjs`.

## Change the rubric

`rubric.md` is the model's instructions, and `src/validate.mjs` enforces its hard limits in code. If you change a limit in one, change the other.

1. Edit `rubric.md`.
2. If you changed a cap, tier, or required field, update `src/config.mjs` and `src/validate.mjs`, and the tests in `test/validate.test.mjs`.
3. Run `npm test`.
4. Set `REVIEWBOT_DRY_RUN` back to unset, and compare run logs on a sample of PRs before posting again.

Rubric changes are not evaluated automatically. Rubric v0.3 has not been evaluated against held-out PRs.

## Turn it off

- Stop it completely: set `REVIEWBOT_ENABLED` to anything but `true`, or delete the variable.
- Keep running but stop posting: delete `REVIEWBOT_DRY_RUN` or set it to `true`.
- Skip one PR: add the label `ci:skip:reviewbot`.
- Remove its identity: uninstall the GitHub App from the repo.

Comments already posted stay on the PRs. Delete them by hand if needed.

## Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| The check does not appear | `REVIEWBOT_ENABLED` is not `true`, the PR is a draft, it is a fork PR, or the PR touches no files matching the workflow's `paths`. |
| `missing env ...` warning | The workflow did not pass a required variable. Check the workflow `env` block. |
| `::warning::` model call failed with 401 | `ANTHROPIC_API_KEY` is wrong or missing. |
| `::warning::` model call failed with 400 | Often an unsupported `REVIEWBOT_MODEL` or the fallback setting. Try `REVIEWBOT_FALLBACKS=off`, or check the model ID. |
| `Create comment-only GitHub App token` fails | `GH_APP_REVIEWBOT_ID` or the PEM secret is wrong, the App is not installed on the repo, or the PEM is missing its `BEGIN` and `END` lines. |
| Run shows `posted: 0` with findings kept | Dry run is on, or `POST_TOKEN` is missing. Check `dry_run` in the log. |
| A comment appears on the wrong line or posting fails with 422 | The anchor line is not in the diff. The bot falls back to posting each comment alone and records failures in `failed` in the log. |
| Same comment posted twice | The fingerprint changed because the bot's wording changed between runs. Low impact, delete the duplicate. |
| No comments on a PR you expected comments on | By design, anything under 0.8 confidence, a taste call that failed the convention gate, or a `human_only` question without a cited inconsistency is dropped. Look at `dropped` in the run log. |

## Trust boundary

The job checks out the PR head and runs the bot code from it. Anyone who can push a branch to this repo can change what the bot does or read `ANTHROPIC_API_KEY`. That is the same access they already have to every workflow secret. Fork PRs never get the key.

PR text, doc text, and diffs are untrusted input to the model. They sit in tagged data blocks, the model has read-only tools limited to three directories, and the model never sees a GitHub token. The Anthropic key lives in the Node process only: the tool subprocesses get a minimal environment (`PATH`, `HOME`, `LC_ALL`).

## Develop and test locally

```bash
cd tools/docs-team-reviewbot
npm ci
npm test
```

The tests use fake clients and make no API calls. They cover diff parsing, validation and caps, the sandboxed tools (path traversal, symlinks, secrets), the tool loop, deduplication, and that only a `COMMENT` review is ever sent.

To try a real review locally, run from the repo root. Without `POST_TOKEN` it is always a dry run.

```bash
export ANTHROPIC_API_KEY=...
export REPO=Kong/developer.konghq.com PR_NUMBER=<n>
export BASE_SHA=$(git merge-base origin/main HEAD) HEAD_SHA=$(git rev-parse HEAD)
export OUT_DIR=/tmp/reviewbot-out
node tools/docs-team-reviewbot/run.mjs
cat /tmp/reviewbot-out/run-log.json
```

## Not built yet

- Collecting 👍 and 👎 reactions per comment, plus whether the suggestion was applied, to decide which rules to keep.
- An evaluation of rubric v0.3 against held-out PRs.
- A real-API run. The code has been tested against a fake API server only.
