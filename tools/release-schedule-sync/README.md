# Release schedule sync

Keeps the **Release Schedule** view on the [Dev site sprints](https://github.com/orgs/Kong/projects/59) project in sync with this repo's [milestones](https://github.com/Kong/developer.konghq.com/milestones).

The view shows one row per upcoming release, placed on its due date. Each row is a draft item titled `Release: <milestone>` with the **Release date** field set. This tool creates and maintains those items, so the team only needs to manage milestones.

## How it works

| Milestone change | Result on the project |
|---|---|
| Created or reopened with a due date | Adds a `Release: <milestone>` draft item with that Release date |
| Due date changed | Updates the item's Release date |
| Renamed | Renames the item |
| Closed, deleted, or due date removed | Archives the item |

Items are matched to milestones by the milestone link in the item's description, for example `https://github.com/Kong/developer.konghq.com/milestone/99`. Draft items without a milestone link are ignored, so you can still add a release item by hand.

## Add a release to the schedule

Create a milestone in this repo and set a due date. The item appears in the Release Schedule view within a minute or two.

Milestones without a due date don't appear in the view.

## When it runs

The [`sync-release-schedule`](../../.github/workflows/sync-release-schedule.yml) workflow runs:

* When a milestone is created, edited, opened, closed, or deleted.
* Once a day at 06:00 UTC, to catch anything missed.
* On demand from the **Actions** tab.

Milestone and scheduled triggers only run from the default branch, so changes to the workflow take effect after they're merged to `main`.

## Requirements

* The workflow uses the `GH_APP_KONG_DOCS` GitHub App token. The app needs organization **Projects: Read and write** permission.
* The project must have a date field named **Release date**.
* The Release Schedule view uses these settings:
  * Layout: Roadmap
  * Filter: `is:draft -is:pr`
  * Date fields: **Release date** for both start and target
  * Zoom: Month

## Run locally

Requires Node 24 and a GitHub token with `project` scope. If `GH_TOKEN` isn't set, the script uses your `gh` CLI login. Run `gh auth refresh -s project` to add the scope.

```sh
cd tools/release-schedule-sync
node index.js --dry-run   # print what would change
node index.js             # apply changes
```

A dry run prints each change it would make, followed by a summary:

```
Create: Release: Gateway 3.16 (2026-11-20)
  (dry run, skipped)
Done. 1 change(s), dry run.
```

These environment variables override the defaults:

| Variable | Default |
|---|---|
| `OWNER` | `Kong` |
| `REPO` | `developer.konghq.com` |
| `PROJECT_NUMBER` | `59` |
| `DATE_FIELD` | `Release date` |

## Troubleshooting

* **`Field "Release date" not found on project 59`**: The token can't read the project, or the field was renamed. Check the token's `project` scope and the field name.
* **`Resource not accessible by integration`**: The GitHub App doesn't have Projects write permission. An org admin needs to add it.
* **An item didn't appear**: Check that the milestone is open and has a due date. Then run the workflow manually from the **Actions** tab.
