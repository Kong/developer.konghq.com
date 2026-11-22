# kong-harnesses versions

Keeps the kong-harnesses documentation on developer.konghq.com in sync with the installed binary and the kong-harnesses releases.

The [`sync-kong-harnesses`](../../.github/workflows/sync-kong-harnesses.yml) workflow runs on a daily schedule and on manual dispatch.
Its `kong-harnesses-versions` job regenerates the help includes and refreshes the release data from the kong-harnesses releases.
Its `kong-harnesses-changelog` job refreshes the changelog.
The two jobs run at the same time, and each opens its own pull request.
GitHub runs a schedule only from the default branch, so the same workflow file is also on `main`.
Its `base` job sends the sync to `release/kong-harnesses` while that branch exists, else to the default branch.
A manual run can name the branch in `dev_site_base_branch`, which must have the scripts in this folder.
Runs of the same job for the same base branch wait for each other.
Each base branch gets two sync pull requests, from the branches `sync-kong-harnesses/releases/<base branch>` and `sync-kong-harnesses/changelog/<base branch>`.
No earlier workflow used a branch named `sync-kong-harnesses`, `sync-kong-harnesses/releases` or `sync-kong-harnesses/changelog`, which would block those names.

The `kong-harnesses-versions` job downloads the newest release for Linux, and checks the archive against `SHA256SUMS.txt` and against the build provenance in `kong-harnesses_<tag>.sigstore.json`.
`gh attestation verify` checks that provenance.
The job reads the releases with a Kong docs GitHub App token (`GH_APP_KONG_DOCS_ID`), and also sets it as `GH_TOKEN` for `fetch-versions.js`.
The install step and `fetch-versions.js` both read every page of releases and take only `vX.Y.Z` tags of releases that aren't drafts or pre-releases, and the job fails when the release data names another latest release than the binary it checked.
It opens the pull request with a second GitHub App token.

Both jobs read the `<owner>/<name>` of the repository that publishes the kong-harnesses releases from the repository secret `KONG_HARNESSES_RELEASES_REPO`, and pass it to the scripts in the environment variable of the same name, so no file in this repository names it and GitHub masks it in the logs.
An administrator of Kong/developer.konghq.com must add that repository secret, with the value `<owner>/<name>` in the same letter case as the repository, before the workflow can run.
GitHub masks only that exact text, and `gh attestation verify` accepts a value in another letter case but prints the name of the repository in its own case.
So right after the releases token step, each job stops with an error when the value isn't the exact `<owner>/<name>` of the repository in its letter case, and the error names neither.
The old name of a renamed or moved repository fails this check too, because GitHub follows it to the new name.
The workflow also masks the owner and the name each on their own, so the job logs show `***` in place of each, also inside archive names and tool output.
Without the secret each job fails with an error that names it.
The workflow, `fetch-versions.js` and the changelog scripts take only an owner of letters, digits and hyphens, and a name of letters, digits, `.`, `_` and `-` that isn't `.` or `..`, and the changelog scripts compare the owner and the name without regard to letter case, as GitHub does.

The manual runbook below does the same work by hand, and stays the way to sync from a local binary.

## How to run the sync

Run the steps in this order:

1. Upgrade the CLI first so the extracted help matches the latest release:

   ```sh
   brew upgrade kong-harnesses
   ```

   The tap is `kong/kong-harnesses`.

2. Update the release data from the kong-harnesses releases:

   ```sh
   export KONG_HARNESSES_RELEASES_REPO='OWNER/NAME'
   export GH_TOKEN='TOKEN'
   node fetch-versions.js
   ```

   Replace `OWNER/NAME` with the repository that publishes the releases, the same value as the repository secret.
   Without `KONG_HARNESSES_RELEASES_REPO` the script exits with an error.
   Replace `TOKEN` with a GitHub token.
   Without `GH_TOKEN` the script sends the request with no token, and when the request fails it exits with a message that asks for `GH_TOKEN`.
   `gh auth token` can supply the token for a logged-in `gh` session.

3. Update the help text from the installed binary:

   ```sh
   node extract-help.js
   ```

   This regenerates `app/_includes/kong-harnesses/help/**` from scratch, then prunes reference pages under `app/kong-harnesses/` whose help includes no longer exist.

4. Update the changelog from `CHANGELOG.md` on `main`, up to the highest published final release:

   ```sh
   export KONG_HARNESSES_RELEASES_REPO='OWNER/NAME'
   export GH_TOKEN='TOKEN'
   bundle exec ruby sync-changelog.rb
   bundle exec ruby check-changelog-links.rb
   ```

   Use the same `OWNER/NAME` and `TOKEN` as in step 2.

   This writes `app/_data/kong-harnesses/changelog.json`, which the [changelog page](../../app/kong-harnesses/changelog.md) prints as a Liquid variable.
   It reads `main`, not the release tag, so a correction to an earlier entry reaches the page, and it keeps a section only when its release is published, because release-please writes a section before the release is out.
   The release-please config of the kong-harnesses releases sets no pre-release or versioning option, so release-please tags each release as `vX.Y.Z`, unless a commit sets the version with a `Release-As:` footer, as the kong-harnesses release process does for a release candidate.
   GoReleaser marks a tag with a pre-release part as a pre-release.
   A published release is one that is not a draft.
   A final release has a `vX.Y.Z` tag and is not marked as a pre-release, the rule (`STABLE_TAG`) of `tools/lib/tool-versions.js` and the versions job, so the page and the release data name the same latest release.
   Each of them compares the numbers of a version as whole numbers of any size.
   A tag with build metadata, as in `v1.2.3+build.2`, is no final release.
   A pre-release, such as `1.2.3-rc.1`, shows only once a final release of the same `X.Y.Z` is published.
   The script reads the version of each heading from the source text and writes it as text, so the page shows a version with `--` as its tag writes it, not with a dash.
   For each release that it leaves out, it prints the version and why: the release is not published, it is marked as a pre-release, it has no `vX.Y.Z` tag, it is a pre-release whose `X.Y.Z` release is not published or is not a final release, or it has no entries for users.
   It also prints each published final release that has no section in the changelog.
   It stops with an error at a release heading with no version, such as `Unreleased`, when the changelog has no section with the version of the highest final release, and when no entry for users is left, so a changelog that lost its sections cannot empty the page.
   It also stops at a release heading whose text on the page does not start with exactly the version of its line, ended by a `]`, a space, a `(` or the end after a `[`, or by a space, a `(` or the end without one, such as one with text right after the compare link, and names the line.
   It also stops at a second release heading with the version of an earlier one, and names the line, and `check-changelog-links.rb` refuses a second release heading on the page that shows the version of an earlier one, so each version names one release.
   Jekyll does not parse a variable as a template, so Liquid syntax in a commit subject stays text.
   Vale checks only Markdown pages, so the commit subjects in this file do not fail the spelling check.
   The page has no links, as the Mesh changelog drops its source links.
   The script takes out only the links that release-please writes, in the exact form of the templates and the subject transform of the pinned release-please action.
   Each address must be `https://github.com` and a path, with no port, user, query, fragment, character reference, or `.` or `..` segment, which a browser resolves to another path.
   The path names the repository of `KONG_HARNESSES_RELEASES_REPO` (`/<owner>/<name>/issues/N`, `/<owner>/<name>/commit/<hash>` or `/<owner>/<name>/compare/<tag>...<tag>`, with any pre-release or build part in a tag), the owner and repository of a closed issue (`/<owner>/<repo>/issues/N`), or a user (`/<name>`).
   The compare link of a release heading goes, and its version stays as text.
   The references at the end of a `*` list entry of one paragraph go with their text: the subject's own `(#N)`, the commit hash, and the `, closes` list of the issues that the commit closes.
   A subject is one line, so an entry with more blocks has no such end.
   A link must be `[label](address)` exactly as release-please writes it, with no title, attribute list (not even an empty `{: }`), reference definition or angle brackets, and with the label that release-please writes, so `[octo/__sample__#456]` matches its issue, and a label with an image, code, an escaped character or an entity does not.
   A link that release-please writes in running text, to an issue as `#N` or to a user as `@name`, becomes its label as text, so `see [#12](…)` gives `see #12`.
   A breaking change note is the author's text, so its `(#N)` stays as `(#N)`, also before a list or a `#### ` line that release-please writes under the note.
   The script refuses any other link or image and names the entry, so that a person writes the entry again in `CHANGELOG.md` on `main`.
   Its errors and those of `check-changelog-links.rb` name the place of an entry, as its release version, section and entry number, and none of its text, because GitHub masks only the exact text of the secret.
   This script counts the entries of a section in `CHANGELOG.md`, also the tooling entries that the page drops, so the number leads straight to the entry to fix.
   `check-changelog-links.rb` reads only the page, so it counts the entries on the page and says "on the page".
   The checks of the whole page below read the page too, so they name the first place that they refuse on the page in the same way, and a code block by its number in its section.
   The check of the text that a reader sees names the release, or the first block that differs when the page and the source hold other releases.
   A place names a release by the version that its `CHANGELOG.md` heading writes, also with `--`, which kramdown shows as a dash, and finds it by the version that the heading shows, not by the order of the headings.
   The checks name a link that release-please does not write so by the line in `CHANGELOG.md` where its entry or block starts, and its release.
   release-please links each `#N` and `@name` of a subject also in code, so such a link in a code span becomes `#N` or `@name` again, as in `` `&#8212;` `` or `` `@local` ``, and the script refuses code that holds any other link.
   Outside code, the writer escapes the `&` of `&#8212;` once the link between its parts goes, so the page still shows `&#8212;`.
   It also refuses a character reference to no character and a hidden code point, raw or as a character reference: a control character other than a tab or a line end, a line or paragraph separator (U+2028, U+2029), a noncharacter, a format character (the Unicode `Cf` category) and any other character that shows nothing by default (the Unicode `Default_Ignorable_Code_Point` property), such as a character that changes the order of text, a variation selector, a Hangul filler or a tag character.
   It allows only a soft hyphen, U+200B to U+200D, U+2060, U+FEFF, the tag characters of the flags of England, Scotland and Wales, and one U+FE0E or U+FE0F right after an emoji, which selects how the emoji shows.
   These change no order, and the address checks read text without them.
   It reads the source lines of each part that it keeps as they came, so it also refuses a CR, which kramdown reads as a line end, and a control character at the end of an entry, which kramdown drops.
   It refuses text with `//`, `www.`, `mailto:`, `xmpp:` or an `@` between two characters of a name, as in `user@host`, outside code, because the site's parser shows such an address as text.
   A value such as `go@1.21` can go in backticks.
   It parses the changelog with the GFM parser and options that the site uses, changes the tree, and writes it back with kramdown's own Markdown writer, so it never rewrites Markdown text with patterns.
   Two changes keep text as text: a `|` does not make a table and a placeholder such as `<name>` is not HTML, also at the start of a line, and the writer escapes both.
   The writer also escapes a block marker at the start of any line of a paragraph, a `~` and a run of `-`, `.` or `>`, and it writes an entity as it was written, a backtick as `&#96;` and a quote mark or dash as its character, so no character becomes Markdown.
   It writes a code block in a language that the site's highlighter does not load, as listed in `app/_plugins/converters/shiki.rb`, as `text`, because Shiki stops the site build on an unknown language.
   A Shiki alias that the file does not name, such as `yml`, is written as `text` too, so the code shows without colors.
   The script refuses the file when it cannot read an entry or the form of that list.
   It refuses what it cannot write back safely, such as a footnote, raw HTML, an HTML comment, a tag that HTML knows or code with a line that the parser reads as the start of a block.
   A strikethrough, which release-please writes from `~~text~~` in a subject, stays as `~~text~~`.
   It then renders its own output again with the site's parser and options and refuses it unless the HTML is the same as that of the tree that it wrote.
   It also refuses the tree unless a reader sees the same text in it as in the source, with only the references at the end of an entry taken out.
   It reads that text and those references from a second rendering of the source and of the tree, with its own reading of each address and label, takes a link as a reference only when kramdown parsed it from `[label](address)` on its line of the source, as the export does, so an anchor of raw HTML is no reference, and takes nothing off a breaking change note or an entry with more than one block.
   It also refuses a code block that lost its language.
   `check-changelog-links.rb` does not trust that: it renders the result with the site's own Markdown converter, reads the HTML with Nokogiri, and stops with an error when the page would hold an element or attribute other than plain text markup, heading IDs and a code block language that the site highlights, a hidden code point, `//`, `www.`, `mailto:`, `xmpp:` or an `@` between two characters of a name outside code, or the address of the `KONG_HARNESSES_RELEASES_REPO` repository or a `.` or `..` segment in a GitHub address in any text.
   It reads the text of each block as a reader sees it, joined across inline markup such as bold, after it undoes character references, percent-encoding and letter case, and drops each tab, line end, format character and other character that shows nothing by default.
   A code span is checked too, so an entry with a `go install` command for that repository stops the sync by design: leave the address out of changelog entries.
   The sync job runs it before it opens the pull request.
   The script filters the releases and sections first and reads the links only in the text it keeps, so a section that is left out cannot stop the sync.
   It keeps only the sections for users (**⚠ BREAKING CHANGES**, **Features**, **Bug Fixes** and **Performance**), so the steps an upgrade needs stay under **⚠ BREAKING CHANGES**.
   It drops every other section, the changes to the repository's own tooling and dependency pins (the tooling scopes in `TOOLING_SCOPES` of `sync-changelog.rb`) outside **⚠ BREAKING CHANGES**, and a release with nothing left.

Commit the generated `app/_data/tools/kong-harnesses.yml`, `app/_includes/kong-harnesses/help/**` and `app/_data/kong-harnesses/changelog.json` files with any page changes from pruning.

## Tests

```sh
npm test
```

The tests cover the shared library in `tools/lib/tool-versions.js` and the kong-harnesses help parser in `extract-help.js` without the binary or the network.
`bundle exec rspec spec/tools/kong-harnesses-versions` in the repository root tests `sync-changelog.rb` and `check-changelog-links.rb`, with a table of entries, a fuzz test with a fixed seed, and random entries in the shape that release-please writes, which the export must all keep, and the [`rspec`](../../.github/workflows/rspec.yml) workflow runs it on each pull request.
