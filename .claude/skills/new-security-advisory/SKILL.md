---
name: new-security-advisory
description: Turn a security team draft (pasted text, a Markdown file, or a Google Doc link) into a published-ready security advisory for developer.konghq.com under app/_support/security/. Use whenever someone wants to publish, add, create, or format a new security advisory, CVE notice, or vulnerability disclosure for the docs site. Extracts CVEs, versions, and patches from the draft, asks for severity and any missing required fields, writes the file in the advisory format, applies house style and Vale term rules, validates frontmatter, and reports judgment calls. Never stages or commits.
argument-hint: <path-or-link-to-draft, or paste the draft>
allowed-tools: Read Write Edit Bash
---

# new-security-advisory

Creates a security advisory page at `app/_support/security/security-advisory-<cve-ids>.md`. Advisories use their own layout (`security_advisory`, set by `jekyll.yml` defaults for `_support/security`). The layout adds the CVE table, the info box (severity, dates, versions, install and upgrade links), and the Contact section. The author writes only frontmatter and narrative.

Read these at run time. Don't copy them into your head from memory:

- `.claude/skills/new-security-advisory/template.md.example`: the body shape and frontmatter example.
- `app/_data/schemas/frontmatter/support.json`: the `advisory` schema. If it disagrees with this skill, the schema wins; tell the user.
- `.github/styles/base/Kongterms.yml`: required product-term substitutions.
- `app/_support/security/security-advisory-cve-2025-15467-cve-2026-1642-cve-2026-1907.md`: a finished example.

## Hard rules

- **Never fabricate.** Versions, dates, CVSS values, mitigations, and impact statements come from the draft or the author. If the draft doesn't say, ask or leave it out.
- **Never infer severity.** Use a severity only when the draft states it for that CVE (for example "7.7 / High" or "Kong severity: Low"), verbatim. Never derive it from a CVSS score. Interactive run: ask the author for missing severities. Batch run (the user said not to ask): omit `severity` and log it.
- **Skip, don't invent.** If a field isn't in the draft, leave it out and log it (field, CVE or section, reason). Only `advisory.cves[].id` is required by the schema; `published`, `severity`, `summary`, versions, and `products` are optional. A page with missing fields is correct; a page with a guessed field isn't.
- **Never read or publish customer data.** Spreadsheets of impacted accounts or customer lists in a Drive folder stay untouched. Don't open them.
- **Never stage or commit.** Leave the new file untracked. No `Co-Authored-By` or "Generated with Claude Code" lines anywhere.
- **No TL;DR.** Advisories have no `tldr`. Don't add one.
- **No Contact section, CVE table, or install/upgrade links in the body.** The layout adds them. Strip them from the draft if present.

## Step 1: Get the draft

Use what the user gave you:

- Pasted text: use it.
- A file path: read it.
- A Google Doc or Drive link: read it with the Drive connector (`read_file_content`). If the connector isn't available, ask the user to paste the text.
- Nothing: ask for the draft. Don't start from an empty template.

**Drive folders.** A folder usually holds the advisory plus an `FAQ` doc, notices that aren't vulnerabilities (EOL, IP reminders, breaking-changes emails), and spreadsheets. Migrate only the advisory doc. List everything else in the report with its link and don't convert it. Use `search_files` with `parentId = '<folder id>'`; ignore the odd `nextPageToken` on an empty tail.

**Strip the email wrapper.** Drafts are customer emails. Remove: `Draft:` or `//DRAFT//` banners, `Subject:` lines, "Hi [Customer Name]" or "Dear Kong Gateway user", "You are receiving this notification...", the Contact block, "Thank you, Kong Support", "[add release date]" placeholders, and "This advisory is published in this knowledge base article" lines (this page replaces the article). Keep the advisory ID.

## Step 2: Extract

From the draft only, pull out:

- The advisory ID if the draft has one (`KONGSA-YYYYMMDD`, goes in `advisory.id`).
- CVE IDs, with a one-line summary and CVSS score and version for each. When a draft gives one assessment for several CVEs (for example "CVE-A/CVE-B"), apply it to each and flag that in the report.
- Per CVE: whether Kong is affected. "Not reachable", "No", or "not affected" is `status: not_affected`; an affected CVE is `status: affected` (including residual risk). Leave `status` out when the draft doesn't say.
- Kong's severity versus the upstream CVSS. If they differ (for example Kong assesses Low, upstream is 8.2 High), `severity` is Kong's and `cvss_score` is omitted; keep both in the body.
- Vector strings, CWE IDs, and GHSA links (body bullets, not frontmatter).
- Affected versions and fixed versions (overall, and per CVE if they differ).
- Per CVE: description, exploit conditions, recommendation, impacted and unaffected products (for example Konnect, or a version series).
- The patch table (impacted range to patched version).
- Publish date, but only a full date with a year ("July 29, 2026"). "Monday August 10th" has no year: omit `published` and flag it. Don't take the year from the advisory ID or the file's Drive date.
- References and any acknowledgements.
- Which products the advisory covers, for `products` and `works_on`.

## Step 3: Ask once (or skip and log)

If the user said not to ask questions (a batch migration), don't ask: omit what's missing, log it for the report, and move on. Otherwise show a compact summary of what you extracted (CVE list, versions, products, date), then ask in one batch for everything missing:

- **Severity for each CVE** the draft doesn't give one for.
- Published date (`YYYY-MM-DD`), if the draft has none.
- Fixed versions, if the draft has none.
- `products` and `works_on`, if ambiguous. Valid `products` values are in `app/_data/schemas/frontmatter/base.json`. `works_on` is `on-prem`, `konnect`, or both.

Let the author correct the extraction in the same reply. Don't ask about anything the draft already answers.

## Step 4: Write the file

**Path:** `app/_support/security/security-advisory-<id>.md`, where `<id>` is the lowercase advisory ID (`kongsa-20260608`) when the draft has one, otherwise the hyphen-joined CVE IDs. Lowercase, hyphen-joined CVE IDs, for example `security-advisory-cve-2026-1907.md`. With more than three CVEs, use the first ID plus `-and-<n>-more`. If the file exists, ask before overwriting.

**Frontmatter:**

```yaml
---
title: "Security Advisory: CVE-A, CVE-B and CVE-C"
content_type: support
description: "<One sentence: what is patched and which products are affected.>"
products:
  - gateway
works_on:
  - on-prem
  - konnect
advisory:
  id: KONGSA-YYYYMMDD       # only when the draft has one
  published: "YYYY-MM-DD"   # only a full date with a year
  updated: "YYYY-MM-DD"     # only for revisions
  cves:
    - id: CVE-YYYY-NNNN
      severity: high        # only when the draft states it
      cvss_score: 7.5       # only when given
      cvss_version: "4.0"   # only when given
      status: affected      # affected | not_affected, only when the draft says
      summary: Short description
  affected_versions:        # one product group (Gateway and AI Gateway)
    - "3.10.0.0 to 3.10.0.8"
  fixed_versions:
    - "3.10.0.9"
  products:                 # instead of the flat lists when versions span products
    - product: mesh         # gateway | ai-gateway | mesh | kic | operator
      affected_versions:
        - "2.13.0 to 2.13.7"
      fixed_versions:
        - "2.13.8"
---
```

Use the flat `affected_versions`/`fixed_versions` for a single product group and `products` when the advisory spans products with their own versions (for example Gateway and Mesh, or KIC and Operator). Don't use both for the same versions. The layout hides any block whose data is missing, and ignores `not_affected` CVEs when it computes the advisory severity.

- Dates are quoted strings.
- `title` is `Security Advisory: ` plus the IDs, joined with commas and a final "and".
- Product names in `description` must use site variables and the whole value must be quoted, for example `"... {{site.base_gateway}} ..."`. An unquoted `{{site.*}}` breaks YAML; a literal product name fails the Kongterms rule.
- Versions are exactly as the draft states them. Write ranges as `A to B` (the draft's `A - B` or `A through B`), and "3.4.17 and earlier" for `<= 3.4.17`. The patch table in the body keeps the draft's own notation.
- Identifiers with underscores in a `summary` (for example `validate_assertion_signature`) need backticks, and then the whole value must be quoted: `summary: "... `name` ..."`. Vale's frontmatter pass flags bare identifiers.
- `description` doesn't use "mitigations" (spellchecker); say "ways to reduce risk".

**Body**, following the template:

1. An opening paragraph: what Kong patched and which products it affects.
2. Any statement that applies to all CVEs (for example "Konnect isn't impacted by CVE-X"), once.
3. One `##` section per CVE, titled with the ID: description and exploit conditions, a bullet list with the severity assessment, CVSS vector, CWE, and GHSA link when the draft has them, then `### Am I affected?`, `### Mitigation`, `### Recommendation`, and `### Impacted products` as the draft provides them (supported versions, then unsupported versions) when they differ from the global lists. Keep the draft's conditions and wording; don't summarize them. Headings can't contain backticks, so write "NGINX slice module" instead of `ngx_http_slice_module`.
   - For a cumulative release with many CVEs, group the not-affected ones (for example OpenSSL) under one `##` with a `###` per CVE and the "Is Kong affected?" answer verbatim, in the draft's order.
4. `## Patches` (or `## Remediation` when the draft uses it): a `{% table %}` with columns "Impacted supported versions" and "Patch", one table per product. Copy the draft's mapping; don't compute it, and don't fix an apparent typo (flag it).
5. `## References`, only when the draft has references or acknowledgements.

## Step 5: Style pass

Apply to the whole file:

- **Product terms** from `Kongterms.yml`, in body and frontmatter: `Kong Gateway` becomes `{{site.base_gateway}}`, `Kong Gateway Enterprise` becomes `{{site.ee_product_name}}`, `Kong AI Gateway` becomes `{{site.ai_gateway_name}}`, `Kong Konnect` becomes `{{site.konnect_product_name}}`, `Kong Mesh` becomes `{{site.mesh_product_name}}`, and so on. Re-read the file if the list has changed. Don't touch text inside code spans or URLs.
- Spell out "SQL injection" instead of "SQLi" (the spellchecker rejects it).
- Kongterms also matches link text, so write `[{{site.mesh_product_name}} CVE-... memory exhaustion](url)`. "Kong API Gateway Enterprise" is `{{site.ee_product_name_official}}`; "Kong Kubernetes Ingress Controller" has no variable and passes as written.
- Real technical terms the spellchecker rejects (for example `libjq`, `multibyte`, `Bleichenbacher`) go in `.github/styles/base/Dictionary.txt`. A new frontmatter key goes in `.github/styles/frontmatter/Keys.txt` (as `status` and `cwe` did), or the CI frontmatter pass flags its value.
- Avoid "currently" (suggestion-level Vale rule); "each supported release" says the same thing.
- No em dashes, en dashes, or dashes as sentence punctuation. Rewrite as two sentences or use a comma, colon, or parentheses. Hyphens in compounds, versions, and code are fine.
- No "above" or "below" for page position. Use "the following" or link the section.
- Short, direct sentences; sentence-case headings; contractions are fine. Cut filler and summaries.
- Version ranges in prose: "3.10.0.0 up to 3.10.0.8". Series: "3.5.x through 3.9.x".
- Relativize links to developer.konghq.com. If a link points to an internal-only domain (for example `support.konghq.com/support/s/`), leave it and flag it. Don't remove it silently.
- The layout supplies install and upgrade links and the Contact section. Drop the draft's "see our installation guide" and "for upgrade information" paragraphs (they link to old docs.konghq.com paths).

## Step 6: Consistency checks (flag, don't fix)

- Every CVE ID matches `CVE-YYYY-NNNN` or longer.
- Every affected range has a fixed version, and no fixed version sits inside an affected range.
- `advisory.affected_versions` and `fixed_versions` match the body and the patch table.
- A "not impacted" claim appears once and doesn't contradict a per-CVE section.
- If the draft says a CVE is not exploitable in Kong products, flag it next to the severity you were given, so Security can confirm the label.
- Dates aren't in the future and aren't earlier than the CVE year.
- A patch table row whose patch is outside the range it patches (for example range `2.7.0 - 2.8.26` patched by `2.7.27`) is a likely source typo. Copy it, flag it.
- A published date that conflicts with another source for the same advisory (a KB page versus the email date). Keep the existing value, flag it.
- Wording Legal may want to review (internal tool names, "self scans" language). Copy it, flag it.

## Step 7: Validate

```bash
npm --prefix tools/frontmatter-validator run validate
vale app/_support/security/<file>.md
```

Run `vale` on the file directly. `make vale` only checks files committed since `origin/main`, so it skips new uncommitted files.

CI runs Vale a second time on the frontmatter only. Replicate it without touching the file:

```bash
KEYS=$(paste -sd'|' .github/styles/frontmatter/Keys.txt); D=$(mktemp -d)
awk 'BEGIN{c=0}/^---$/{c++;next}c==1{print}c>=2{exit}' "$F" \
  | perl -pe "s/^\\s*($KEYS):.*\$//g" \
  | perl -0777 -pe 'open(my $d,"<",".github/styles/frontmatter/Dictionary.txt");while(my $w=<$d>){chomp $w;next unless length $w;s/\Q$w\E//g;}s/^#.*$//gm;' > "$D/$(basename $F)"
vale --config=./.vale.ini "$D/$(basename $F)"
```

After the last page of a batch, run a production build once (`JEKYLL_ENV=production bundle exec jekyll build --config jekyll.yml,<cache config> --destination <scratch dir>`) and confirm exit 0 and no "Liquid Exception". The dev server skips generators, so some failures only show there. Fix mechanical issues (term substitutions, dashes, quoting) and re-run until clean. Report anything you couldn't fix.

## Step 8: Report

Print a short summary:

- The file path.
- What came from the draft versus what the author supplied.
- Judgment calls and flags from Step 6, and any link flagged in Step 5.
- Skipped fields: a table of field, CVE or section, and reason (for example `published`, "draft says 'Monday August 10th' with no year").
- Drive items that weren't converted (FAQs, notices, spreadsheets) with their links.
- Open questions for the author.
- Validator and Vale results.
- How to preview: run `make run` and open `/support/security/<slug>/`.
- "Nothing was staged or committed."

Don't start the dev server yourself unless the user asks.

## Drafts without a CVE, old drafts, and multi-notice docs

- A draft with no CVE ID is still valid. Omit `cves`, put a severity the draft states in `advisory.severity`, and the layout skips the CVE table. Never look up or guess a CVE ID.
- `works_on` is required by the schema. If the draft doesn't say, pick from what the draft implies (for example, hybrid and traditional mode imply `on-prem`) and list it under judgment calls.
- A Google Doc can hold several notices, a pasted older advisory, and an internal action-item table. Convert only the notice the title names, and log everything else as skipped. Internal next steps, owners and customer lists never go on the page.
- Don't convert incident notices (no CVE, no versions, unknown resolution status). Report them as open questions instead of publishing a possibly stale status.
- Replace the word "blacklist" with "denylist" (Vale `base.Terms`).
