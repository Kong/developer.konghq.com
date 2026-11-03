---
title: "Exports in {{site.ai_cost_management}}"
content_type: reference
layout: reference_with_schema

products:
  - ai-cost-management

min_version:
  ai-gateway: '2.3'

works_on:
  - konnect

tools:
  - konnect-api

breadcrumbs:
  - /ai-cost-management/

tags:
  - ai
  - governance

description: "Exports in {{site.ai_cost_management}} copy your organization's usage events into files you can download, either once or on a repeating schedule."

schema:
  api: konnect/ai-cost-management
  path: /schemas/AICostExportInput

api_specs:
  - konnect/ai-cost-management

faqs:
  - q: Why did my export fail?
    a: |
      Call [`GET /v1/ai-cost-management/exports/{exportId}`](/api/konnect/ai-cost-management/v1/#/operations/get-export) and check the `failure_reason` field in the response:
      * A `query_limit_exceeded` failure means the export read more data than one job can use.
      Try a shorter range, narrower filters, fewer FOCUS tag keys, or a smaller charge period (for example, `hour` instead of `day`).
      * An `attempts_exhausted` failure means every attempt hit a transient error. If you see this error, create the same export again.
  - q: Why can't I download a file from my export?
    a: |
      Files are only downloadable from an export with `status: succeeded`.
      Exports expire after 30 days, and their files are deleted.

      An export that is still `pending` or `running` hasn't produced files yet.
  - q: Why does a scheduled export have fewer events than a one-time export of the same range?
    a: |
      Scheduled exports start six hours after a period ends so that late events can be stored first, but events can still arrive after that window.
      A one-time export run later includes any events that arrived after the scheduled export ran.
      Scheduled exports are never refreshed.
      To capture late events for a past period, create a one-time export.


related_resources:
  - text: "{{site.ai_cost_management}}"
    url: /ai-cost-management/
  - text: Analytics and debugging in {{site.ai_cost_management}}
    url: /ai-cost-management/analytics-and-debugging/
  - text: Attribution in {{site.ai_cost_management}}
    url: /ai-cost-management/attribution/
---

Exports in {{site.ai_cost_management}} write your stored usage events to downloadable files.
Use them to analyze spend in a spreadsheet, load it into a data warehouse, or reconcile it with a model provider's FOCUS data.

Create a one-time export to answer a question about a specific time range.
Create a schedule to keep a recurring copy, for example a daily file for your finance team's reporting.

## Configuration

Configuration options control what data an export holds, what format its files use, and how FOCUS rows are structured.

### Datasets

The dataset controls what each row in an export holds and how the files divide the time range.

<!--vale off-->
{% table %}
columns:
  - title: Dataset
    key: dataset
  - title: What it holds
    key: what
  - title: Files
    key: files
rows:
  - dataset: "`usage_events`"
    what: One row per stored usage event, with the same fields the Events list shows.
    files: One file per day of the range.
  - dataset: "`focus`"
    what: |
      Cost and usage rows in the [FinOps FOCUS](https://focus.finops.org/what-is-focus/) format, for tools that load cloud spend.
    files: One file per calendar month of the range.
{% endtable %}
<!--vale on-->

### File formats

Exports are available in the following formats:

<!--vale off-->
{% table %}
columns:
  - title: Format
    key: format
  - title: Compression
    key: compression
  - title: Extension
    key: extension
  - title: Best for
    key: best_for
rows:
  - format: CSV
    compression: None
    extension: "`.csv`"
    best_for: Spreadsheets and tools that import CSV.
  - format: CSV (gzip)
    compression: gzip
    extension: "`.csv.gz`"
    best_for: Smaller downloads over slow connections.
  - format: Parquet
    compression: Zstandard
    extension: "`.parquet`"
    best_for: Data warehouses and analytics tools.
{% endtable %}
<!--vale on-->

A period with no matching events still produces a file, with a header row only (CSV) or zero records (Parquet).

### FOCUS options

FOCUS exports have additional options that control how rows are formed and what the cost columns hold.

#### FOCUS version

The FOCUS version controls what the standard cost columns (`BilledCost`, `EffectiveCost`, `ListCost`, `ContractedCost`) hold.
Both versions carry the {{site.ai_gateway}}-reported cost estimate in `x_ReportedCost`.

{:.warning}
> **Warning**: If you load a FOCUS 1.3 file alongside a model provider's own FOCUS data, the standard cost columns count the same spend twice.
> Use FOCUS 1.4 when combining exports with provider data.

<!--vale off-->
{% table %}
columns:
  - title: Version
    key: version
  - title: Standard cost columns
    key: cost_columns
rows:
  - version: "`1.3`"
    cost_columns: |
      The {{site.ai_gateway}}-reported cost estimate. Counts the same spend as the provider's FOCUS data.
  - version: "`1.4`"
    cost_columns: |
      `0`. The estimate is in `x_ReportedCost` only. Safe to combine with provider data.
{% endtable %}
<!--vale on-->

#### Charge period

The charge period sets the length of each FOCUS row's aggregation window, in the export's time zone.
* `day` produces one row per calendar day
* `hour` produces one row per hour

An `hour` charge period also reduces the risk of a `query_limit_exceeded` failure on large datasets.

#### Tag keys

Tag keys name the tag dimensions that split FOCUS rows.
A row's `Tags` column holds each configured key and its value for the events the row aggregates.
Each key must be between 1 and 128 characters, and a FOCUS export supports at most 64 tag keys.

## Export lifecycle

The export lifecycle covers how an export progresses after creation, how to download its files, and how scheduled exports behave.

### Status

An export runs asynchronously, and the `status` field tracks its progress.

<!--vale off-->
{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: meaning
rows:
  - status: "`pending`"
    meaning: |
      The export is queued. One export per organization runs at a time.
  - status: "`running`"
    meaning: |
      The export is in progress. {{site.ai_cost_management}} is reading events and writing files.
  - status: "`succeeded`"
    meaning: |
      Files are ready to download, until `expires_at` (30 days after the export finishes).
  - status: "`failed`"
    meaning: |
      The export stopped without files. Check the `failure_reason`.
  - status: "`expired`"
    meaning: |
      The export succeeded but its 30-day download window has passed.
      The export record remains with its file list, but the files are deleted.
{% endtable %}
<!--vale on-->

### Downloading files

You can download files from a successful export through short-lived URLs that the API returns.
Each URL is valid for five minutes and works with a plain `GET` request without an `Authorization` header.

{:.warning}
> **Warning**: A download URL is a bearer credential. Anyone who holds it can download the file until it expires.

Each file in the export's `files` list has a `size_bytes` and a `sha256` field.
The `manifest.json` file describes the export and lists each data file with its size and SHA-256 digest.

The `files` list doesn't include the manifest. To download it, request a download URL with `manifest.json` as the filename.
You can verify a download by comparing its size and SHA-256 checksum against those values.

### Scheduled exports

A scheduled export runs automatically at the end of each period.
A scheduled export runs automatically at the end of each period.
Usage events don't always arrive in real time.
The export starts six hours after the period ends, so that events that arrive late can be stored first.
For example, a request that happens at 11:58 PM might not be processed and stored until 1 AM.

Each schedule exports each period once and never refreshes it, even when events arrive after the export ran.
A failed scheduled export stays `failed` and the schedule doesn't retry it.
To capture late events or fill a failed period, create a one-time export of the same range.

When a schedule resumes from `paused`, the periods that ended while it was paused are skipped.
After an outage, a schedule catches up on at most the 31 most recent periods that ended while it was `active`.

To change a schedule, send a `PUT` request to the [`/v1/ai-cost-management/export-schedules/{scheduleId}` endpoint](/api/konnect/ai-cost-management/v1/#/operations/replace-export-schedule) with the full schedule, because an omitted `filters` clears the filters.
Set `status` to `paused` to pause the schedule and to `active` to resume it.
The change applies to periods that end after it, and existing exports don't change.

## Set up an export

You can create a one-time export or a recurring schedule from the {{site.konnect_short_name}} UI or the API.

### Set up a one-time export

{% navtabs "set-up-one-time-export" %}
{% navtab "Konnect UI" %}

Create a one-time export:
1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. In the Cost Management sidebar, click **Exports**.
1. Click **New export**.
1. Under **Dataset**, select **Usage events** or **FOCUS cost and usage**.
1. Under **Format**, select **CSV**, **CSV (gzip)**, or **Parquet**.
1. If you selected **FOCUS cost and usage**, choose a **FOCUS version**, a **Charge period**, and any **Tag keys**.
1. Under **Range**, set the start and end dates and the time zone.
1. *(Optional)* Add filters to export only the events that match.
1. *(Optional)* Add labels to help find the export later.
1. Click **Create export**.

When the export status is `succeeded`, the page lists each file with a **Download** button.
Click **Download** to get a file, or click **Download manifest** to get the manifest file with checksums for all files.

{% endnavtab %}
{% navtab "Konnect API" %}

Create a one-time export:
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/exports
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  dataset: usage_events
  format: csv
  compression: none
  from: "2026-10-01T00:00:00Z"
  to: "2026-11-01T00:00:00Z"
  time_zone: UTC
{% endkonnect_api_request %}
<!--vale on-->

Poll [`GET /v1/ai-cost-management/exports/{exportId}`](/api/konnect/ai-cost-management/v1/#/operations/get-export) until the `status` is `succeeded`. You may have to wait a few seconds.
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/exports/$EXPORT_ID
status_code: 200
method: GET
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
{% endkonnect_api_request %}
<!--vale on-->

Then, request a download URL for one file at a time.
Replace `EXPORT_ID` with the export's `id` and `FILE_NAME` with a name from the `files` list, for example `2026-10-01.csv`:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/exports/$EXPORT_ID/downloads
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  file: $FILE_NAME
{% endkonnect_api_request %}
<!--vale on-->

The response includes a `url` field.
Open the URL in a browser, or send a plain `GET` request to that URL (without an `Authorization` header), to download the file.

{% endnavtab %}
{% endnavtabs %}

### Set up a scheduled export

{% navtabs "set-up-scheduled-export" %}
{% navtab "Konnect UI" %}

Create a scheduled export:
1. In {{site.konnect_short_name}}, go to **Cost Management** > **Exports**.
1. Click **Schedules**, then **New schedule**.
1. Enter a **Name**.
1. Under **Cadence**, select **Daily**, **Weekly**, or **Monthly**.
1. Set the **Time zone**.
1. Under **Dataset**, select the dataset and format.
1. *(Optional)* Add filters and labels.
1. Click **Create schedule**.

{% endnavtab %}
{% navtab "Konnect API" %}

Create a scheduled export:
<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-cost-management/export-schedules
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  name: daily-usage-events
  cadence: daily
  time_zone: UTC
  dataset: usage_events
  format: csv
  compression: none
{% endkonnect_api_request %}
<!--vale on-->

For the full set of schedule parameters, see the [`/v1/ai-cost-management/export-schedules` endpoint](/api/konnect/ai-cost-management/v1/#/operations/create-export-schedule).

{% endnavtab %}
{% endnavtabs %}

## Limitations

Exports and export schedules are subject to the following limits.

<!--vale off-->
{% table %}
columns:
  - title: Limit
    key: limit
  - title: Value
    key: value
rows:
  - limit: Maximum range
    value: 13 months
  - limit: Pending one-time exports
    value: 20 at a time
  - limit: Export schedules
    value: 20
  - limit: FOCUS tag keys
    value: 64 per export
  - limit: File retention
    value: 30 days after the export succeeds
  - limit: Download URL lifetime
    value: 5 minutes
{% endtable %}
<!--vale on-->
Exports that a schedule creates don't count toward the pending one-time export limit.

The following limitations also apply:

* An export runs once and is never refreshed. A later export of the same range can hold events an earlier one doesn't have, because events can arrive after the range ends.
* Export files stay in the region where they were created.
* Labels on a one-time export can't change after creation.
* A schedule's `cadence` and `time_zone` can't change after creation. Delete the schedule and create a new one to change either field.

## Schema

{% entity_schema %}
