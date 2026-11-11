# Prose rules

These rules enforce the standard of the `prose-drafting` skill and `app/contributing/style-guide.md` on pages written without the skill.

Comment only on changed lines, and only when you can write the exact replacement. Silence is the default.

Post at most one finding per rule per PR. List every repeat in the same comment.

## Always flag

- **Trailing "no".** A verb followed by "no" and a noun reads as positive until the reader hits "no" ("receives no signal", "requires no setup", "has no limit", "there are no defaults"). Negate the verb: "doesn't receive a signal", "doesn't require setup", "doesn't have a limit".

  A noun followed by "with no" becomes "without" ("a model with no target" becomes "a model without a target").

  Not a violation: "no longer", "no more than", "no later than", "no matter", and "no-" compounds. Also not a violation: a sentence that starts with "No" as its subject ("No plugin runs before this one"), and "no" inside code, a quoted error message, a UI label, or a literal `yes`/`no` value.
- **Hedging words.** Delete "simply", "just" (meaning "merely" or "only"), "easily", "obviously", "of course", "clearly" and "genuinely". Suggest the sentence without the word. Not a violation: "just" meaning "exactly" or "a moment ago", "just-in-time", text inside code or a quoted message, UI labels, partner text.
- **"Real" as a qualifier.** "A real X", "a real-world X" used as intensity. Delete the word or name the actual difference. Not a violation: "real-time", "real user" in a monitoring product sense, and a field named `real_*`.
- **"By hand".** Replace "by hand" with "manually".
- **Meta-commentary about the docs.** A sentence whose subject is the documentation or the drafting process ("this is confirmed in the schema", "verified", "demonstrated in this documentation", "this page assumes"). Suggest deleting it, not rewording it.
- **Marketing language.** "Effortless", "seamless", "powerful", "robust", "best-in-class", "industry-leading", or "our X makes Y easy". Suggest the problem-first form: state the reader's situation and what the feature does about it, using only facts on the page. Not a violation: a product or feature name that contains the word, partner-authored text.
- **Recommendation wording.** "Kong recommends" and "it is recommended" become "we recommend". A recommendation with no reason on the page or in a linked reference is a question, never a suggestion: ask why.
- **Verb precision.** "Makes use of" becomes "uses". "In order to" becomes "to". "Obtain the software" becomes "install the software" (or the actual action). A doubled infinitive such as "port to use to communicate" becomes "port used to communicate".
- **Conditional openers.** A sentence that starts with an adjective-led or fragment opener ("With X enabled,", "Disabled, it ...", "When enabled,") becomes a full clause: "When X is enabled, ...". Not a violation: "With" introducing an instrument or a how-to action ("With decK, run ...").
- **"Not X, Y" constructions.** A sentence that says what a thing is not before saying what it is ("This isn't a cache, it's a buffer", "not just X, but Y"). Rewrite as the positive statement. Not a violation: a correction of a mistake readers commonly make, where the negative half is the warning.
- **"Plus" as a conjunction.** "Plus" joining two clauses or list items where "and" would do the job ("a streaming custom policy, plus a global policy that turns it on"). Replace with "and". Not a violation: "plus" as a mathematical/arithmetic operator, or a product/plan name containing "Plus" (for example, "Konnect Plus").
- **Mismatched-subject "and" tack-on.** A passive clause containing an "if"/"unless" conditional, followed by ", and [new subject] ..." that switches to a different grammatical subject for the next step. Rewrite as active voice and split into two sentences, one per subject: "The groups listed in a claim are created if they don't already exist, and the principal joins them" becomes "Kong creates any group from the claim that doesn't already exist. The principal then joins one of those groups." Not a violation: a short compound sentence with no embedded conditional where both clauses share the same subject or describe one continuous action, such as "Kong creates the resource and returns its ID."
- **Markdown pipe tables.** A `| a | b |` table or a `|---|---|` separator row outside a code fence. This repo renders tables through the `{% table %}` Liquid block, so rewrite the table as one and keep every cell.
- **Inline FAQ heading.** A `## FAQ` or `## FAQs` heading in the page body. FAQs go in the `faqs:` frontmatter list. Raise as a question if the writer did not ask for an FAQ.
- **Bold lines used as headings.** A line that is only bold text and acts as a heading or sub-heading (`**Flattened Configuration**:`). Suggest a real `###` heading, or a plain sentence. Not a violation: bold UI labels and click targets in steps, bold lead-in labels in bullets, bold inside a table cell, a warning label, and partner-authored text.
- **Heading case.** A heading in title case ("Loading Values From Environment Variables", "Choose a Workflow"). `app/contributing/style-guide.md` requires sentence case: capitalize the first word and proper nouns only. Suggest the exact sentence-case heading. Not a violation: product, feature and entity names, acronyms (TLS, YAML), plugin names, a version prefix ("3.12.x breaking changes"), the Kong terms "Admin API" and "Kong Manager", and headings inside code or partner-authored text. Renaming a heading changes its anchor only when the words change, so check links that point at it.
- **Dense bullets and paragraphs.** A bullet that runs four or more lines, or a paragraph that carries several separate rules or conditions. Suggest splitting it into shorter bullets or sentences, one rule each, and write the split out. Not a violation: a code block, a table cell, a reference description that must stay in one sentence for accuracy.

## Flag only when the sentence stands without its heading, intro or lead-in

- **Heading-dependent first sentence.** The first sentence under an H2 or H3 starts with "This", "It", "These", "They" or "That" and leans on the heading for its subject. Rewrite it so it names the subject: under "Authorization code flow", write "The authorization code flow is ...", not "This is ...". Applies to `faqs:` answers too: an answer that starts with "It" or "This feature" must restate the subject by name. Not a violation: a sentence that starts with a pronoun but is the second or later sentence of the section, steps in a numbered procedure, and sections whose first sentence is an imperative.
- **Literal "In this guide" opener.** The first sentence of the page body is "In this guide", "In this tutorial", "This guide shows", "Read this page when", "Use this page to" or "Use this workflow to", or otherwise tells the reader when to read the page instead of saying what the thing is. Rewrite it to say what the thing is and how it relates to a use case or concept. A later sentence in the intro may use that framing.
- **tldr that overviews.** A how-to `tldr.a` starts with "In this guide", "You'll learn" or "This guide", or summarizes the sections instead of stating how to do the task. Rewrite it as the terse answer an experienced reader can act on. An intro paragraph that repeats the tldr is a restated-content finding in the Core rules.
- **Description that describes itself.** A frontmatter `description` starts with "In this reference, you'll find", "This page", "This guide" or "Learn how". Rewrite it as a one- or two-sentence summary that says what the page is, then what it covers.
- **Bare example lead-in.** A sentence ends in a colon before a block and says only "For example:", "Example:", "Run the following:", "Run this command:" or "Use the following:". Rewrite it so it names the resource or the point the block shows, using facts visible in the block: "Create an AI Model Provider to store the provider credentials:". Not a violation: `title:` or `description:` fields in example YAML, and a lead-in that already names what the block shows.

## Do not flag

- Anything Vale already reports: dashes, positional words (including "as above"), `Kongctl` casing, stray `<a id>` anchor tags, "e.g.", temporal words, repeated words, banned terms.
- Quoted error text, partner-authored third-party plugin prose, and text inside code, YAML values, or `{% %}` tags.
- Pre-existing issues on unchanged lines.
