---
name: changelog-review
description: Copyedit Kong changelog and release-notes entries (product changelogs with headers like "## Kong Enterprise", "#### Core/Plugin/Clustering", entries followed by PR/Jira links). Use whenever the user asks to copyedit, review, or proofread a changelog, release notes, or a list of "Fixed an issue where..." / "Added ..." entries, including pasted directly into the conversation. Applies Kong-specific changelog style rules (contractions, parameter backticking, plugin name casing, third-person phrasing, duplicate and security-vagueness flagging) on top of the general developer.konghq.com style guide. Not for generating a new release changelog from a git diff (that's the release-changelog skill) or for authoring a brand-new entry from a code diff — this is for copyediting existing changelog text someone already wrote.
---

# Changelog review

Copyedit Kong changelog entries for correctness and clarity. Apply the general developer.konghq.com style guide (active voice, plain language, no em dashes, sentence-case headings) as the baseline, and the overrides below wherever they conflict with it.

Fix spelling, grammar, run-on sentences, and unclear or awkward phrasing — a reader should understand what changed on the first pass. This is copyediting, not polishing: don't reword an entry that already reads clearly. But a real run-on (an "although" clause, a parenthetical, and a main clause all strung together) is a defect, and fixing it can mean splitting it into two sentences, not just swapping a word.

## Rules

1. **Leave contractions as written.** Don't add or remove them ("do not" and "don't" both stay as given). This is the one place changelogs diverge from the general style guide, which avoids contractions outside warnings.

2. **Backtick every parameter, config key, identifier, and code-shaped literal.** `verify_signature`, `completion_tokens`, a header name, or a literal string the code actually produces (`"userdata: NULL"`) all need backticks if they don't have them. Check every such token in an entry — it's easy to backtick the obvious one and miss a second.

3. **Plugin name casing depends on position.** The bolded lead-in label uses the schema name: lowercase, hyphenated (`**rate-limiting**:`). Everywhere else in the entry's prose, use the proper display name: title case, spaced (`the Rate Limiting plugin...`). Watch for the slug leaking into prose, or the proper name leaking into the lead-in.

4. **Datakit is the one proper name to double check.** Capital D, rest lowercase, not "DataKit". Only in prose; the lead-in stays `**datakit**:`.

5. **"Data plane," "control plane," and "hybrid mode" aren't proper nouns.** Ordinary sentence case only, not a capitalized "Data Plane" mid-sentence. Easy to miss since it reads as a deliberate choice, not an error.

6. **Flag duplicate entries, don't merge them.** Look for the same change listed twice, literally or reworded (symptom-first vs. fix-first, terse vs. detailed). Compare by what actually changed, not by text similarity. When two entries look like duplicates, flag both with your reasoning and let the reviewer decide, especially if you're not fully confident.

7. **Entries start with a verb and end with a period.** "Fixed an issue where...", "Added...", "Improved..." — not a fragment, not missing the trailing period.

8. **"Users/their," never "you/your."** An entry addressing the reader directly ("you can configure your settings") should describe the user in third person instead ("users can configure their settings").

9. **Flag, don't fix, security entries that look over-specific.** A fix for a security issue should describe the change generically, not detail the exploit or vulnerability mechanics. If an entry reads like it's naming the specific attack vector or how to reproduce it, flag it for the reviewer rather than rewriting it yourself — judging how much detail is safe to publish isn't a copyediting call.

## Process

Go entry by entry, section by section, and check each entry against every rule above before moving on — an entry can need more than one fix (a backtick and a plugin-casing fix at once), so don't stop at the first thing you catch. Do rules 1-5 and 7-8 per entry first; duplicates (rule 6) need a second pass across all entries, since a duplicate is a relationship between two entries, not a property of one.

Treat every changelog as unseen, even one that looks like a near-duplicate of one you reviewed earlier in the conversation. Leaning on memory of what a similar changelog needed, instead of re-checking this one's literal text against the rules, is exactly how real errors get skipped.

## Output

Ask whether to save the review to a file or print it inline, unless the user already said which in their request. If saved to a file:

- Default location: this skill's own `temp/` directory (`.claude/skills/changelog-review/temp/`), regardless of where the changelog being reviewed lives. Use `<filename>-review.md` when reviewing a file on disk, or `changelog-review.md` when reviewing pasted text.
- Save somewhere else only if the user names a specific directory for this run.
- Reply with just the file path and a one-line summary (entries changed, duplicates flagged) — don't also paste the full review inline.

Either way, include only entries you changed, each as one bullet:

```markdown
- Original entry: _<original text>_

  Fixed entry:
  ```
  <corrected text>
  ```
  Changed: <what changed and why>
```

Skip untouched entries entirely — don't list them as "no change." If nothing needed a fix, say so in the file instead of listing entries.

Suspected duplicates (rule 6) go in their own `## Suspected duplicates` section after the edits, each as a bullet quoting both entries with your reasoning. Flagged security entries (rule 9) go in their own `## Flagged for security review` section, each as a bullet quoting the entry with what looks over-specific. Omit either section if there's nothing to put in it.
