# kong-harnesses versions

Keeps the kong-harnesses documentation on developer.konghq.com in sync with the installed binary and its GitHub releases.

The [`sync-kong-harnesses`](../../.github/workflows/sync-kong-harnesses.yml) workflow runs both scripts on a daily schedule and on manual dispatch: it regenerates the help includes, then refreshes the release data and the changelog from the `Kong/kong-harnesses` releases, and opens a pull request. GitHub runs a schedule only from the default branch, so the same workflow file is also on `main`. Its `base` job sends the sync to `release/kong-harnesses` while that branch exists, else to the default branch. A manual run can name the branch in `dev_site_base_branch`, which must have the scripts in this folder. Runs for the same base branch wait for each other. Each base branch gets its own sync pull request, from the branch `sync-kong-harnesses/releases/<base branch>`. No earlier workflow used a branch named `sync-kong-harnesses` or `sync-kong-harnesses/releases`, which would block that name.

The `kong-harnesses-versions` job downloads the newest release for Linux, and checks the archive against `SHA256SUMS.txt` and against the build provenance in `kong-harnesses_<tag>.sigstore.json`, as `scripts/install-release.sh` in `Kong/kong-harnesses` does. `gh attestation verify` checks that provenance. The job reads the releases with a Kong docs GitHub App token (`GH_APP_KONG_DOCS_ID`), and also sets it as `GH_TOKEN` for `fetch-versions.js`. The install step and `fetch-versions.js` both read every page of releases and take only `vX.Y.Z` tags of releases that aren't drafts or pre-releases, and the job fails when the release data names another latest release than the binary it checked. It opens the pull request with a second GitHub App token.

The manual runbook below does the same work by hand, and stays the way to sync from a local binary.

## How to run the sync

Run the steps in this order:

1. Upgrade the CLI first so the extracted help matches the latest release:

   ```sh
   brew upgrade kong-harnesses
   ```

   The tap is `kong/kong-harnesses`.

2. Update the release data from the `Kong/kong-harnesses` releases:

   ```sh
   GH_TOKEN=<token> node fetch-versions.js
   ```

   Set `GH_TOKEN` to a GitHub token. Without it the script sends the request with no token, and when the request fails it exits with a message that asks for `GH_TOKEN`. `gh auth token` can supply the token for a logged-in `gh` session.

3. Update the help text from the installed binary:

   ```sh
   node extract-help.js
   ```

   This regenerates `app/_includes/kong-harnesses/help/**` from scratch, then prunes reference pages under `app/kong-harnesses/` whose help includes no longer exist.

4. Update the changelog from `CHANGELOG.md` on `main`, up to the highest published release, which `fetch-versions.js` also marks as the latest:

   ```sh
   GH_TOKEN=<token> bundle exec ruby sync-changelog.rb
   bundle exec ruby check-changelog-links.rb
   ```

   This writes `app/_data/kong-harnesses/changelog.json`, which the [changelog page](../../app/kong-harnesses/changelog.md) prints as a Liquid variable. It reads `main`, not the release tag, so a correction to an earlier entry reaches the page, and it keeps a section only when its release is published, because release-please writes a section before the release is out. It keeps a release candidate only once the final release of the same version is published. It stops with an error at a release heading with no version, such as `Unreleased`, when the changelog has no section for the highest published release, and when no entry for users is left, so a changelog that lost its sections cannot empty the page. Jekyll does not parse a variable as a template, so Liquid syntax in a commit subject stays text. Vale checks only Markdown pages, so the commit subjects in this file do not fail the spelling check. The page has no links, as the Mesh changelog drops its source links. The script takes out only the links that release-please writes, in the exact form of the templates and the subject transform of the pinned release-please action. Each address must be `https://github.com` and a path, with no port, user, query, fragment or character reference. The path names the repository (`/Kong/kong-harnesses/issues/N`, `/Kong/kong-harnesses/commit/<hash>` or `/Kong/kong-harnesses/compare/<tag>...<tag>`, with any prerelease or build part in a tag), the owner and repository of a closed issue (`/<owner>/<repo>/issues/N`), or a user (`/<name>`). The compare link of a release heading goes, and its version stays as text. The references at the end of a `*` list entry of one paragraph go with their text: the subject's own `(#N)`, the commit hash, and the `, closes` list of the issues that the commit closes. A subject is one line, so an entry with more blocks has no such end. A label must be the one that release-please writes, element for element, so `[octo/__sample__#456]` matches its issue, and a label with an image, code or an entity does not. A link that release-please writes in running text, to an issue as `#N` or to a user as `@name`, becomes its label as text, so `see [#12](…)` gives `see #12`. A breaking change note is the author's text, so its `(#N)` stays as `(#N)`, also before a list or a `#### ` line that release-please writes under the note. The script refuses any other link or image and names the entry, so that a person writes the entry again in `CHANGELOG.md` on `main`. It also refuses code that holds a link, as release-please links each `#N` and `@user` of a subject also in code, a character reference to no character, and a control character, a character that changes the order of text (U+061C, U+200E, U+200F, U+202A to U+202E and U+2066 to U+2069) or a noncharacter, raw or as a character reference. A zero width space stays, because it changes no order and the address check reads text without it. It refuses text with `//`, `www.`, `mailto:`, `xmpp:` or an `@` between two characters of a name, as in `user@host`, outside code, because the site's parser shows such an address as text. A value such as `go@1.21` can go in backticks. It parses the changelog with the GFM parser and options that the site uses, changes the tree, and writes it back with kramdown's own Markdown writer, so it never rewrites Markdown text with patterns. Two changes keep text as text: a `|` does not make a table and a placeholder such as `<name>` is not HTML, also at the start of a line, and the writer escapes both. The writer also escapes a block marker at the start of any line of a paragraph, a `~` and a run of `-`, `.` or `>`, and it writes an entity as it was written, a backtick as `&#96;` and a quote mark or dash as its character, so no character becomes Markdown. It writes a code block in a language that the site's highlighter does not load, as listed in `app/_plugins/converters/shiki.rb`, as `text`, because Shiki stops the site build on an unknown language. A Shiki alias that the file does not name, such as `yml`, is written as `text` too, so the code shows without colors. The script refuses the file when it cannot read an entry or the form of that list. It refuses what it cannot write back safely, such as a footnote, raw HTML, an HTML comment, a tag that HTML knows, a strikethrough or code with a line that the parser reads as the start of a block. It then renders its own output again with the site's parser and options and refuses it unless the HTML is the same as that of the tree that it wrote. It also refuses the tree unless a reader sees the same text in it as in the source, with only the references at the end of an entry taken out. It reads that text and those references from a second rendering of the source and of the tree, with its own reading of each address and label, takes nothing off a breaking change note or an entry with more than one block, and refuses a link that kramdown writes with a character reference. It also refuses a code block that lost its language. `check-changelog-links.rb` does not trust that: it renders the result with the site's own Markdown converter, reads the HTML with Nokogiri, and stops with an error when the page would hold an element or attribute other than plain text markup, heading IDs and a code block language that the site highlights, a control, bidirectional or noncharacter code point, `//`, `www.`, `mailto:`, `xmpp:` or an `@` between two characters of a name outside code, or the `Kong/kong-harnesses` address in any text. It reads the text of each block as a reader sees it, joined across inline markup such as bold, after it undoes character references, percent-encoding and letter case. A code span is checked too, so an entry such as `go install github.com/Kong/kong-harnesses/cmd/...` stops the sync by design: leave the address out of changelog entries. The sync job runs it before it opens the pull request. The script filters the releases and sections first and reads the links only in the text it keeps, so a section that is left out cannot stop the sync. It keeps only the sections for users (**⚠ BREAKING CHANGES**, **Features**, **Bug Fixes** and **Performance**), so the steps an upgrade needs stay under **⚠ BREAKING CHANGES**. It drops every other section, the changes to the repository's own tooling, reviews and dependency pins (the `ci`, `ksai`, `threat-model` and `deps` scopes) outside **⚠ BREAKING CHANGES**, and a release with nothing left.

Commit the generated `app/_data/tools/kong-harnesses.yml`, `app/_includes/kong-harnesses/help/**` and `app/_data/kong-harnesses/changelog.json` files with any page changes from pruning.

## Tests

```sh
npm test
```

The tests cover the shared library in `tools/lib/tool-versions.js` and the kong-harnesses help parser in `extract-help.js` without the binary or the network. `bundle exec rspec spec/tools/kong-harnesses-versions` in the repository root tests `sync-changelog.rb` and `check-changelog-links.rb`, with a table of entries, a fuzz test with a fixed seed, and random entries in the shape that release-please writes, which the export must all keep, and the RSpec workflow runs it on each pull request.
