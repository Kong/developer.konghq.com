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
- **Never infer severity.** Ask the author for every CVE's severity (critical, high, medium, low), even when a CVSS score is present.
- **Never stage or commit.** Leave the new file untracked. No `Co-Authored-By` or "Generated with Claude Code" lines anywhere.
- **No TL;DR.** Advisories have no `tldr`. Don't add one.
- **No Contact section, CVE table, or install/upgrade links in the body.** The layout adds them. Strip them from the draft if present.

## Step 1: Get the draft

Use what the user gave you:

- Pasted text: use it.
- A file path: read it.
- A Google Doc or Drive link: read it with the Drive connector (`read_file_content`). If the connector isn't available, ask the user to paste the text.
- Nothing: ask for the draft. Don't start from an empty template.

## Step 2: Extract

From the draft only, pull out:

- CVE IDs, with a one-line summary and CVSS score and version for each.
- Affected versions and fixed versions (overall, and per CVE if they differ).
- Per CVE: description, exploit conditions, recommendation, impacted and unaffected products (for example Konnect, or a version series).
- The patch table (impacted range to patched version).
- Publish date, references, and any acknowledgements.
- Which products the advisory covers, for `products` and `works_on`.

## Step 3: Ask once

Show a compact summary of what you extracted (CVE list, versions, products, date), then ask in one batch for everything missing or required:

- **Severity for each CVE.** Always.
- Published date (`YYYY-MM-DD`), if the draft has none.
- Fixed versions, if the draft has none.
- `products` and `works_on`, if ambiguous. Valid `products` values are in `app/_data/schemas/frontmatter/base.json`. `works_on` is `on-prem`, `konnect`, or both.

Let the author correct the extraction in the same reply. Don't ask about anything the draft already answers.

## Step 4: Write the file

**Path:** `app/_support/security/security-advisory-<cve-ids>.md`. Lowercase, hyphen-joined CVE IDs, for example `security-advisory-cve-2026-1907.md`. With more than three CVEs, use the first ID plus `-and-<n>-more`. If the file exists, ask before overwriting.

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
  published: "YYYY-MM-DD"
  updated: "YYYY-MM-DD"   # only for revisions
  cves:
    - id: CVE-YYYY-NNNN
      severity: high
      cvss_score: 7.5       # only when given
      cvss_version: "4.0"   # only when given
      summary: Short description
  affected_versions:
    - "3.10.0.0 to 3.10.0.8"
  fixed_versions:
    - "3.10.0.9"
---
```

- Dates are quoted strings.
- `title` is `Security Advisory: ` plus the IDs, joined with commas and a final "and".
- Product names in `description` must use site variables and the whole value must be quoted, for example `"... {{site.base_gateway}} ..."`. An unquoted `{{site.*}}` breaks YAML; a literal product name fails the Kongterms rule.
- Versions are exactly as the draft states them.

**Body**, following the template:

1. An opening paragraph: what Kong patched and which products it affects.
2. Any statement that applies to all CVEs (for example "Konnect isn't impacted by CVE-X"), once.
3. One `##` section per CVE, titled with the ID: description and exploit conditions, `### Recommendation`, and `### Impacted products` (supported versions, then unsupported versions) when they differ from the global lists.
4. `## Patches`: a `{% table %}` with columns "Impacted supported versions" and "Patch". Copy the draft's mapping; don't compute it.
5. `## References`, only when the draft has references or acknowledgements.

## Step 5: Style pass

Apply to the whole file:

- **Product terms** from `Kongterms.yml`, in body and frontmatter: `Kong Gateway` becomes `{{site.base_gateway}}`, `Kong Gateway Enterprise` becomes `{{site.ee_product_name}}`, `Kong AI Gateway` becomes `{{site.ai_gateway_name}}`, `Kong Konnect` becomes `{{site.konnect_product_name}}`, `Kong Mesh` becomes `{{site.mesh_product_name}}`, and so on. Re-read the file if the list has changed. Don't touch text inside code spans or URLs.
- Spell out "SQL injection" instead of "SQLi" (the spellchecker rejects it).
- No em dashes, en dashes, or dashes as sentence punctuation. Rewrite as two sentences or use a comma, colon, or parentheses. Hyphens in compounds, versions, and code are fine.
- No "above" or "below" for page position. Use "the following" or link the section.
- Short, direct sentences; sentence-case headings; contractions are fine. Cut filler and summaries.
- Version ranges in prose: "3.10.0.0 up to 3.10.0.8". Series: "3.5.x through 3.9.x".
- Relativize links to developer.konghq.com. If a link points to an internal-only domain (for example `support.konghq.com/support/s/`), leave it and flag it. Don't remove it silently.

## Step 6: Consistency checks (flag, don't fix)

- Every CVE ID matches `CVE-YYYY-NNNN` or longer.
- Every affected range has a fixed version, and no fixed version sits inside an affected range.
- `advisory.affected_versions` and `fixed_versions` match the body and the patch table.
- A "not impacted" claim appears once and doesn't contradict a per-CVE section.
- If the draft says a CVE is not exploitable in Kong products, flag it next to the severity you were given, so Security can confirm the label.
- Dates aren't in the future and aren't earlier than the CVE year.

## Step 7: Validate

```bash
npm --prefix tools/frontmatter-validator run validate
vale app/_support/security/<file>.md
```

Run `vale` on the file directly. `make vale` only checks files committed since `origin/main`, so it skips new uncommitted files. Fix mechanical issues (term substitutions, dashes, quoting) and re-run until clean. Report anything you couldn't fix.

## Step 8: Report

Print a short summary:

- The file path.
- What came from the draft versus what the author supplied.
- Judgment calls and flags from Step 6, and any link flagged in Step 5.
- Validator and Vale results.
- How to preview: run `make run` and open `/support/security/<slug>/`.
- "Nothing was staged or committed."

Don't start the dev server yourself unless the user asks.
