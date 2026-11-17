# Output template

Use this structure for every review, whether printed inline or saved to a file. Replace each `<placeholder>`. Omit any section that has nothing to report.

List edited entries in the same order they appear in the source changelog. Keep the source's section headings, and don't regroup, sort, or reverse entries.

Formatting rules:

- Give every entry its own `####` heading with the source line number, or a range such as `Lines 38-44` when the entry spans several lines. The range tells the reviewer which lines to select when pasting a suggestion into a PR comment.
- Quote the original text in a blockquote, joined onto one line. Don't wrap it in italics.
- Never indent the `suggestion` block or anything else, so the reviewer can copy it as is.
- Don't add horizontal rules between entries. The headings separate them.

````markdown
# Changelog review: <changelog name or PR>

## <Source section heading, for example "Kong Enterprise">

### <Source subsection heading, for example "Fixes, Plugin">

#### Line <number>

> <original text>

```suggestion
- <corrected text>
```

**Changed**: <what changed and why>

#### Lines <start>-<end>

> <original text>

```suggestion
<corrected text>
```

**Changed**: <what changed and why>

## Suspected duplicates

#### Lines <number> and <number>

> <first entry>

> <second entry>

<Why these look like duplicates, and what might differ. Leave the decision to the reviewer.>

## Flagged for security review

#### Line <number>

> <entry>

<What looks over-specific, for example the attack class or trigger it names. Don't rewrite the entry.>
````

If nothing needed a fix, replace the whole review with a single line saying so.
