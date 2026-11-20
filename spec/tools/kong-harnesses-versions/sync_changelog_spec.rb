# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../tools/kong-harnesses-versions/sync-changelog'
require_relative '../../../tools/kong-harnesses-versions/check-changelog-links'

RSpec.describe KongHarnessesChangelog do
  # The spec loads the site plugins, which send code blocks to Shiki. The sync job
  # renders them with plain kramdown, and so does this spec.
  before do
    allow_any_instance_of(Kramdown::Converter::Html).to receive(:convert_codeblock) do |converter, element, indent| # rubocop:disable RSpec/AnyInstance
      converter.original_convert_codeblock(element, indent)
    end
  end

  def exported(markdown, published = ['1.0.0'])
    described_class.export(markdown, published: published, highest: published.last)
  end

  def section(body, title = 'Features')
    "## 1.0.0\n\n### #{title}\n\n#{body}\n"
  end

  def code(markdown)
    Nokogiri::HTML5.fragment(KongHarnessesChangelogLinks.html(markdown)).css('code').map { |node| node.text.chomp }
  end

  issue = 'https://github.com/Kong/kong-harnesses/issues/1'
  commit = "https://github.com/Kong/kong-harnesses/commit/abc1234#{'0' * 33}"

  release_please_changelog = <<~MARKDOWN
    # Changelog

    ## [0.17.1](https://github.com/Kong/kong-harnesses/compare/v0.17.0...v0.17.1) (2026-11-19)


    ### ⚠ BREAKING CHANGES

    * **profile:** run login again after the upgrade


    ### Bug Fixes

    * **profile:** accept plain http for a gateway on loopback ([#417](https://github.com/Kong/kong-harnesses/issues/417)) ([802a984](https://github.com/Kong/kong-harnesses/commit/802a9848c49528cc52bb72365b6100ea68e30183))
    * **ksai:** let autofix change the Go module files
    * **deps:** update Go
    * **docs:** follow the Claude Code settings {{ unchanged }} {% endraw %} ([#418](https://github.com/Kong/kong-harnesses/issues/418)) ([43de8e5](https://github.com/Kong/kong-harnesses/commit/43de8e59a1b2c3d4e5f60718293a4b5c6d7e8f90))


    ### Documentation

    * **release:** say how a release lists its upgrade steps

    ## [0.17.0](https://github.com/Kong/kong-harnesses/compare/v0.16.1...v0.17.0) (2026-11-18)


    ### Continuous Integration

    * run the tests on Windows
  MARKDOWN

  it 'publishes only the user-facing sections and entries, with no links' do
    expect(exported(release_please_changelog, ['0.17.1'])).to eq(<<~MARKDOWN)
      ## 0.17.1 (2026-11-19)

      ### ⚠ BREAKING CHANGES

      * **profile:** run login again after the upgrade

      ### Bug Fixes

      * **profile:** accept plain http for a gateway on loopback
      * **docs:** follow the Claude Code settings \\{\\{ unchanged }} \\{% endraw %}
    MARKDOWN
  end

  # Each case gives the source entry and the entry that the page gets. Only the
  # references that release-please writes at the end of an entry go, and the text of
  # code stays as it is.
  [
    ["* **cli:** fix x ([#1](#{issue})) ([abc1234](#{commit}))", '* **cli:** fix x'],
    ["* **cli:** fix x ([abc1234](#{commit})), closes [#1](#{issue}) [#2](https://github.com/Kong/kong-harnesses/issues/2)", '* **cli:** fix x'],
    ["* fix x ([abc1234](#{commit})), closes [Kong/other#3](https://github.com/Kong/other/issues/3) [other#4](https://github.com/Kong/other/issues/4)", '* fix x'],
    ["* fix x ([abc1234](#{commit})), closes [kong-harnesses#7](https://github.com/Kong/kong-harnesses/issues/7)", '* fix x'],
    # The label of a reference is compared as a reader sees it, here as `octo/sample#456`.
    ["* fix x ([abc1234](#{commit})), closes [octo/__sample__#456](https://github.com/octo/__sample__/issues/456)", '* fix x'],
    ["* fix x &#40;[&#35;1](#{issue})&#41;", '* fix x'],
    ["* fix x ([`#1`](#{issue}))", '* fix x'],
    # release-please links every `#N` and `@user` of a subject, so such a link in running
    # text becomes its label.
    ["* fix [#1](#{issue})'s crash", '* fix #1’s crash'],
    ["* **cli:** see [#12](https://github.com/Kong/kong-harnesses/issues/12) and [@bob-x](https://github.com/bob-x) ([#1](#{issue})) ([abc1234](#{commit}))",
     '* **cli:** see #12 and @bob-x'],
    ["* a \"q,\" [#1](#{issue}) \"r\" b", '* a “q,” #1 “r” b'],
    ["* rename `--foo`[#1](#{issue})`--bar`", '* rename `--foo`#1`--bar`'],
    ["* [#1](#{issue})", '* \\#1'],
    ["1. First\n2. [#1](#{issue})\n3. Second", "1.  First\n2.  \\#1\n3.  Second"],
    ["* fix ([#1](#{issue}), [#2](https://github.com/Kong/kong-harnesses/issues/2))", '* fix (#1, #2)'],
    ["* fix [&#35;1](#{issue}) now", '* fix #1 now'],
    ['* fix x (#1) ([#2](https://github.com/Kong/kong-harnesses/issues/2))', '* fix x (#1)'],
    ["* fix x\n  * nested ([#1](#{issue}))", "* fix x\n  * nested (#1)"],
    ["> fix x ([#1](#{issue}))", '> fix x (#1)'],
    ["* **cli:** ([#1](#{issue}))", '* **cli:**'],
    ["* run `printf 'a  b'`  twice ([#1](#{issue}))", "* run `printf 'a  b'` twice"],
    ["* <profile> now works ([#1](#{issue}))", '* \\<profile> now works'],
    ["* **cli:** fix x ([abc1234](#{commit}))\n\n  more text", "* **cli:** fix x\n\n  more text"],
    ["* **cli:** fix x ([abc1234](#{commit}))\n  * nested", "* **cli:** fix x\n  * nested"],
    # Text that only looks like Markdown stays text, so the writer escapes it.
    ['* literal \\[mode](optional)', '* literal \\[mode\\](optional)'],
    ['* accept values with a | delimiter', '* accept values with a \\| delimiter'],
    # An entity stays an entity, so it cannot start a table, emphasis or a code span.
    ['* **cli:** use &#124; between values', '* **cli:** use &#124; between values'],
    ['* use &#42;literal&#42; now', '* use &#42;literal&#42; now'],
    ['* use &#96;literal&#96; now', '* use &#96;literal&#96; now'],
    ['* use &#42;a&#42; and &#126;&#126;c&#126;&#126;', '* use &#42;a&#42; and &#126;&#126;c&#126;&#126;'],
    ['* use \\~~b\\~~', '* use \\~\\~b\\~\\~'],
    # After a hard line break, every line of a paragraph can start a block.
    ["* **cli:** old flag removed.\\\n  \\## 9.9.9 (2026-01-01)", "* **cli:** old flag removed.  \n  \\## 9.9.9 (2026-01-01)"],
    ["* a\\\n  \\# b", "* a  \n  \\# b"],
    ["* a\\\n  \\> b", "* a  \n  \\> b"],
    ["* a\\\n  1\\. b", "* a  \n  1\\. b"],
    ["* a\\\n  \\- b", "* a  \n  \\- b"],
    # Kramdown reads `--` as a dash, so each `-` of a run keeps its escape.
    ["* Before\\\n  \\-\\-\\-", "* Before  \n  \\-\\-\\-"],
    ['* use a\\-\\-b, a\\.\\.\\.b and a\\>\\>b', '* use a\\-\\-b, a\\.\\.\\.b and a\\>\\>b'],
    ["* Before\\\n  \\=\\=\\=", "* Before  \n  \\==="],
    # Bold or emphasis cannot start with a line break, so the line break goes before it.
    ["* a _\\\n  b_ c", "* a   \n  *b* c"],
    ["* a **\\\n  b** c", "* a   \n  **b** c"],
    # Two line breaks in a row end a paragraph, also in emphasis, so one goes.
    ["* a _b\\\n  \\\n  c_ d", "* a *b  \n  c* d"],
    # Kramdown's writer gives a rule as `* * *`, which after a list marker is a rule alone.
    ['* ___', '* ___'],
    # Two backslashes at the end of a line are a line break.
    ['* in C:\\\\', '* in C:&#92;'],
    ['* run profile get <profile> or `profile get <profile>`', '* run profile get \\<profile> or `profile get <profile>`'],
    ['* run profile get \\<profile>', '* run profile get \\<profile>'],
    # A placeholder at the start of a line is text too.
    ["* run it\n  <name> at the start", '* run it \\<name> at the start'],
    ["* run it\\\n  <name> at the start", "* run it  \n  \\<name> at the start"],
    # A quote mark, a dash and an entity show as they did, and an entity is text.
    ["* use it's \"x\"", '* use it’s “x”'],
    ['* a\\--- b', '* a-– b'],
    ['* &#44;', '* &#44;'],
    # Kramdown shows `>>` and `<<` next to a space with a no-break space.
    ['* Append x >> y.', "* Append x\u00a0» y."],
    ['* Prepend y << x.', "* Prepend y «\u00a0x."],
    # A paragraph after a reference definition stays a paragraph of its own.
    ["* a\n  {: .x}\n  [r]: https://example.com/pull/3\n  b", "* a\n\n  b"],
    # The last entry after a loose one reads back as loose.
    ["* \n[r]: https://example.com/x\nb\\\n  c\n* d", "* b  \n   c\n\n* d"],
    # Kramdown shows an ordered list from 1 whatever its first number.
    ["3. a\n4. b", "1.  a\n2.  b"],
    # The site's highlighter knows sh, but not rust.
    ["* run:\n\n  ```sh\n  koha up\n  ```", "* run:\n\n      koha up\n  {: .language-sh}"],
    ["* run:\n\n  ```rust\n  fn main() {}\n  ```", "* run:\n\n      fn main() {}\n  {: .language-text}"],
    # The language stays when the code block has other attributes, which go.
    ["* run:\n\n  ```sh\n  koha up\n  ```\n  {: #custom}", "* run:\n\n      koha up\n  {: .language-sh}"],
    ["* run:\n\n  ~~~&#58;\n  code\n  ~~~", "* run:\n\n      code\n  {: .language-text}"],
    # A code block of only white space shows nothing and goes.
    ["* a\n\n  ```sh\n  ```", '* a'],
    # An empty entry stays, also between two lists.
    ["* a\n\n3. \n\n* b", "* a\n\n1.  \n\n* b"],
    ["1. a\n\n3. \n\n5. b", "1.  a\n\n2.  \n3.  b"],
    # A line of code that starts with a number reads back as code.
    ["* the value `1.2\n  2.1.3` here", "* the value `1.2\n  2.1.3` here"],
    # Code spans as kramdown pairs them, also across the lines of a paragraph.
    ['* ``<a>``` x', '* `<a>`&#96; x'],
    ['* a ``x```y` b', '* a `x``y` b'],
    # The site's table parser pairs an escaped backtick with the one of a code span.
    ['* \\`a `x|y` b', '* &#96;a `x|y` b'],
    ["* run `curl\n  https://example.com/x` now", "* run `curl\n  https://example.com/x` now"],
    ['* a \\\\` https://example.com/x ` end', '* a \\\\``  https://example.com/x  `` end'],
    ["* **cli:** run this after the upgrade:\n\n>     kong-harnesses profile get <profile> --url http://h/x",
     "* **cli:** run this after the upgrade:\n\n>     kong-harnesses profile get <profile> --url http://h/x"]
  ].each do |entry, expected|
    it "exports #{entry.inspect}" do
      expect(exported(section(entry))).to eq(section(expected))
    end
  end

  # The site's parser gives no node for an address in text, and only a guess could say
  # where it ends, so the export refuses such an entry and names it.
  [
    '* see https://github.com/Kong/kong-harnesses/issues/3 first',
    '* see (https://example.com/foo) ok',
    '* see <HTTPS://GitHub.com/Kong/kong-harnesses/issues/2> now',
    '* see https://exa**mple**.com/a',
    '* literal \\[foo](https://example.com) next',
    '* x ` <profile> https://example.com/a ` y',
    '* **cli:** https://example.org"restart now" after setup.',
    '* see https://example.com/a&#133;word now',
    '* see https://example.com/a…word now',
    *%w[&#9; &#10; &#32;].map { |entity| "* see https://example.com/a#{entity}word now" },
    "* go https://example.com/a\u00a0word",
    "* see 'https://example.com/a' word",
    '* fix https://example.com/a’s crash',
    '* see www.example.org now',
    '* mail me@example.org now',
    '* write to mailto:me@example.org now'
  ].each do |entry|
    it "refuses the address in #{entry.inspect}" do
      expect { exported(section(entry)) }.to raise_error(/an address in the text of "/)
    end
  end

  # Any other link, with a label or an address that release-please does not write, or
  # in a place where it writes no such link, is refused, and the entry is named.
  [
    "* fix ([#1](#{issue}), [#2](#{issue}))",
    *['https://github-com', 'https://githubXcom', 'https://evilgithub.com', 'https://github.com.evil.example', 'http://github.com', 'https://github.com:443',
      'https://u@github.com', 'https://GitHub.com'].flat_map do |site|
      ["* fix x ([#1](#{site}/Kong/kong-harnesses/issues/1))", "* fix x ([abc1234](#{site}/Kong/kong-harnesses/commit/abc1234#{'0' * 33}))",
       "* fix [#1](#{site}/Kong/kong-harnesses/issues/1) now", "* thanks [@bob](#{site}/bob)"]
    end,
    "* fix x ([#1](#{issue}?x=1))",
    "* fix x ([#1](#{issue}#y))",
    "* fix x ([abc1234](#{commit}?x=1))",
    '* fix x ([#1](https://github.com/Other/kong-harnesses/issues/1))',
    '* fix x ([#1](https://github.com/Kong/other/issues/1))',
    "* fix x ([abc1234](https://github.com/Kong/other/commit/abc1234#{'0' * 33}))",
    "* fix x ([abc1234](#{commit})), closes [octo/x#4](https://github.com/octo/y/issues/4)",
    "* fix x ([abc1234](#{commit})), closes [other#4](https://github.com/octo/other/issues/4)",
    '* fix x ([abc1234](https://github.com/Kong/kong-harnesses/commit/abc1234))',
    "* fix x ([abc1234](#{commit})), closes [Kong/kong-harnesses#7](https://github.com/Kong/kong-harnesses/issues/8)",
    '* fix x ([#1](https://github.com/Kong/kong-harnesses/pull/1))',
    '* fix x ([kong-harnesses#7](https://github.com/Kong/kong-harnesses/issues/7))',
    '* thanks [@Bob](https://github.com/Bob)',
    '* thanks [@a/b](https://github.com/a/b)',
    '* thanks [@bob](https://github.com/bob?x)',
    '* thanks [bob](https://github.com/bob)',
    '* see <https://example.com/a>word',
    '* a "q," <https://example.com/x> "r" b',
    "* fix (#1) ([#2](#{issue})) ([abc1234](#{commit}))",
    "* fix x ([#2](#{issue})) ([abc1234](#{commit}))",
    "* fix x ([abc1234](https://github.com/Kong/kong-harnesses/commit/abc1235#{'0' * 33}))",
    "* fix x ([abc1234](#{commit})) now",
    "* fix x [abc1234](#{commit})",
    "* fix x ([abc1234](#{commit})) closes [#1](#{issue})",
    "* fix x ([abc1234](#{commit})), closes [Kong/other#3](https://example.com/Kong/other/issues/3)",
    "* fix x **([abc1234](#{commit}))**",
    '* see [docs/release.md](docs/release.md) now',
    '* see [2024](https://example.org) now',
    '* see [defaced](https://github.com/Kong/kong-harnesses/pull/1)',
    '* **a:** [mailto:help@example.org](https://example.org/help)',
    '* **a:** [https://example.org/?a=1&amp;b=2](https://example.org/?a=1&amp;b=2)',
    '* see ![the diagram](https://example.com/a.png)',
    "* see [x][r]\n\n[r]: https://example.com/x"
  ].each do |entry|
    it "refuses the link in #{entry.inspect}" do
      expect { exported(section(entry)) }.to raise_error(/has a link in "/)
    end
  end

  # The release-please subject transform links `#N` and `@user` also in code, so code
  # with a link is refused too.
  [
    "* run `foo [#123](#{issue})` now",
    "* see `\\[#1](#{issue}) then [#1](#{issue})` now",
    '* see `[@bob](https://github.com/bob)` now',
    "* run:\n\n  ```sh\n  see [x](https://example.com/x)\n  ```"
  ].each do |entry|
    it "refuses the link in the code of #{entry.inspect}" do
      expect { exported(section(entry)) }.to raise_error(/a link in the code of "/)
    end
  end

  it 'refuses a link in a heading other than the compare link of the release' do
    expect { exported("## [1.0.0](https://example.com/compare/v0.9.0...v1.0.0)\n\n### Features\n\n* add\n") }.to raise_error(/has a link in "1.0.0"/)
    expect { exported("## [1.0.0](https://github.com/Kong/kong-harnesses/compare/v0.9.0...v1.0.1)\n\n### Features\n\n* add\n") }.to raise_error(/has a link in "1.0.0"/)
    expect { exported("## [1.0.0 now](https://github.com/Kong/kong-harnesses/compare/v0.9.0...v1.0.0)\n\n### Features\n\n* add\n") }.to raise_error(/has a link in "1.0.0 now"/)
    ['https://github.com.evil.example/Kong/kong-harnesses', 'https://githubXcom/Kong/kong-harnesses', 'https://github.com/Kong/other'].each do |base|
      expect { exported("## [1.0.0](#{base}/compare/v0.9.0...v1.0.0)\n\n### Features\n\n* add\n") }.to raise_error(/has a link in "1.0.0"/)
    end
    expect { exported("## [1.0.0](https://github.com/Kong/kong-harnesses/compare/v0.9.0...v1.0.0?x)\n\n### Features\n\n* add\n") }.to raise_error(/has a link in "1.0.0"/)
    expect(exported("## [1.0.0](https://github.com/Kong/kong-harnesses/compare/v0.9.0-rc.1...v1.0.0) (2026-01-01)\n\n### Features\n\n* add\n"))
      .to eq("## 1.0.0 (2026-01-01)\n\n### Features\n\n* add\n")
  end

  it 'changes no text inside a code block' do
    [
      "* set it:\n\n  ```toml\n  [mode]: automatic\n  see [x] and <profile>\n\n\n\n### Documentation\n* **ci:** [#1]\n  ```",
      "* ~~~sh\n  echo 'https://example.com/docs'\n  ~~~",
      "* or:\n\n      [mode]: automatic\n\n      ## not a heading <b>",
      "* entry\n\n      code\n  https://example.com",
      "* run this:\n  ```sh\n  kong-harnesses login\n  ```",
      "* run:\n\n  ```sh\n  a\n\n  b\n  ```",
      "* run:\n\n  ```sh\n  a\n    \n  b\n  ```"
    ].each do |entry|
      expect(code(exported(section(entry)))).to eq(code(section(entry)))
    end
  end

  it 'refuses what it cannot write back safely' do
    expect { exported(section("* see [^1] now\n\n[^1]: a note")) }.to raise_error(/footnote/)
    expect { exported(section('<div>x</div>')) }.to raise_error(/raw HTML/)
    ['* a <!-- note --> b', '* a <del>x</del> b', '* a <b>x</b> b', '* a ~~x~~ b'].each do |entry|
      expect { exported(section(entry)) }.to raise_error(/raw HTML or a strikethrough/)
    end
    expect { exported(section("* a `x\n  <profile>` y")) }.to raise_error(/code with a line that starts a block/)
  end

  # A control character shows nothing, raw or as a character reference, and Check B must
  # not read one as a mark.
  ["\u0000", "\u0001", "\u0005", "\u007f", "\u0085", '&#0;', '&#1;', '&#x2;', '&#11;', '&#13;', '&#x7f;', '&#127;'].each do |control|
    it "refuses the control character #{control.inspect}" do
      expect { exported(section("* fix it (#{control}) now")) }.to raise_error(/control character/)
    end
  end

  it 'reads no character of the text as a mark' do
    expect(described_class.reading(described_class.html(described_class.parse("* fix it (\u0002) and (\u0003)\n")))).to eq("fix it (\u0002) and (\u0003)")
    expect(described_class.reading(described_class.html(described_class.parse("* fix it (I) and (C), closes R\n")))).to eq('fix it (I) and (C), closes R')
  end

  it 'takes off only the `(#N)` at the end of a breaking change note' do
    expect(exported(section("* **profile:** run login again ([#1](#{issue}))", '⚠ BREAKING CHANGES')))
      .to eq(section('* **profile:** run login again', '⚠ BREAKING CHANGES'))
    expect { exported(section("* **profile:** run login again ([#1](#{issue})) ([abc1234](#{commit}))", '⚠ BREAKING CHANGES')) }.to raise_error(/has a link in "/)
    # release-please writes a `#### ` line of the note under it, which kramdown reads as
    # text of the same paragraph, so the `(#N)` is in running text and stays as text.
    expect(exported(section("* **api:** drop v1 ([#12](https://github.com/Kong/kong-harnesses/issues/12))\n    #### Deleted\n    - endpoint 1", '⚠ BREAKING CHANGES')))
      .to eq(section("* **api:** drop v1 (#12) #### Deleted\n  * endpoint 1", '⚠ BREAKING CHANGES'))
  end

  it 'leaves out the repository tooling scopes, also with a nested scope, but keeps an upgrade step' do
    expect(exported("## 1.0.0\n\n### Bug Fixes\n\n* **deps(actions):** bump\n* **ci(release):** retry\n* **cli(help):** fix\n"))
      .to eq("## 1.0.0\n\n### Bug Fixes\n\n* **cli(help):** fix\n")
    expect(exported("## 1.0.0\n\n### ⚠ BREAKING CHANGES\n\n* **deps:** install Go 1.30 first\n\n### Bug Fixes\n\n* **deps:** update Go\n"))
      .to eq("## 1.0.0\n\n### ⚠ BREAKING CHANGES\n\n* **deps:** install Go 1.30 first\n")
  end

  it 'drops a section with no entry left' do
    expect(exported("## 1.0.0\n\n### Features\n\n* add\n\n### Bug Fixes\n\n* **ci:** retry\n"))
      .to eq("## 1.0.0\n\n### Features\n\n* add\n")
  end

  it 'publishes only the sections of published releases' do
    changelog = "preamble\n\n## 0.19.0\n\n### Features\n\n* later\n\n## 0.18.0-rc.2\n\n### Features\n\n* not out\n\n" \
                "## [0.18.0-rc.1](https://github.com/Kong/kong-harnesses/compare/v0.17.1...v0.18.0-rc.1)\n\n### Features\n\n* candidate\n\n## 0.17.1\n\n### Features\n\n* add\n"
    expect(exported(changelog, %w[0.18.0-rc.1 0.17.1])).to eq("## 0.17.1\n\n### Features\n\n* add\n")
    # 0.18.0 never shipped, so its candidate stays out even below a later release.
    expect(exported(changelog, %w[0.18.0-rc.1 0.17.1 0.19.0])).to eq("## 0.19.0\n\n### Features\n\n* later\n\n## 0.17.1\n\n### Features\n\n* add\n")
    expect(exported("## 0.18.0\n\n### Features\n\n* final\n\n## [0.18.0-rc.1](https://github.com/Kong/kong-harnesses/compare/v0.17.1...v0.18.0-rc.1)\n\n### Features\n\n* candidate\n", %w[0.18.0-rc.1 0.18.0]))
      .to eq("## 0.18.0\n\n### Features\n\n* final\n\n## 0.18.0-rc.1\n\n### Features\n\n* candidate\n")
    expect { exported("## Unreleased\n\n### Features\n\n* secret\n") }.to raise_error(/no version/)
  end

  it 'refuses a changelog with no section for the highest release or with nothing left' do
    expect { exported("# Changelog\n") }.to raise_error(/no section for 1\.0\.0/)
    expect { exported("## 0.17.1\n\n### Features\n\n* add\n", %w[0.17.1 0.18.0]) }.to raise_error(/no section for 0\.18\.0/)
    expect { exported("## 1.0.0\n\n### Documentation\n\n* explain\n") }.to raise_error(/no entries for users/)
  end

  it 'reads the changelog on main up to the highest published release, not the newest one' do
    requested = []
    get = lambda do |path, _accept|
      requested << path
      next [200, '## [0.18.0](x) (2026-12-01)\n\n### Features\n\n* not out yet\n\n## 0.17.1\n\n### Features\n\n* add\n'.gsub('\n', "\n")] unless path.include?('/releases?')

      releases = [%w[v0.16.2 false false], %w[v1.0.0-beta false false], %w[v0.19.0 true false], %w[v0.18.0-rc.1 false true], %w[v0.17.1 false false]]
      [200, JSON.generate(releases.map { |tag, draft, prerelease| { tag_name: tag, draft: draft == 'true', prerelease: prerelease == 'true' } })]
    end
    Dir.mktmpdir do |dir|
      out_file = File.join(dir, 'changelog.json')

      expect(described_class.sync(out_file: out_file, get: get)).to eq('v0.17.1')
      expect(requested.last).to end_with('CHANGELOG.md?ref=main')
      expect(JSON.parse(File.read(out_file))).to eq('markdown' => "## 0.17.1\n\n### Features\n\n* add\n")
    end
  end

  # Pieces of Markdown that are hard to write back. The addresses are on another host,
  # because the repository's address in code stops the sync by design, and a piece can
  # land in code. A link or an address is refused unless it is a reference at the end
  # of an entry, so only a few pieces have one.
  pieces = ['[x](https://example.com/pull/1)', '<https://example.com/q>',
            '`a <b> https://example.com/c`', '``d`e``', '`', '<profile>', '|', '[', ']', '(', ')',
            '**', '_', '~~', '~~~', '```', '    ', "\n", "\n\n", '> ', '* ', '1. ', '# ',
            '[r]', "\n[r]: https://example.com/pull/3\n",
            'word', ' ', "it's", '"q"', "'q'", '--', '&amp;', '{: .x}', ':', '-', ',', 'closes', '#1', 'abc1234',
            '<!-- note -->', '<del>x</del>', '<b>', '</b>', "\n3. ", "\n<name> ",
            '[#7](https://github.com/Kong/kong-harnesses/issues/7)', '[@alice](https://github.com/alice)'] +
           # Every ASCII punctuation character as an entity, and every character that the
           # GFM parser escapes with a backslash. A slash and a backslash are left out,
           # because the check refuses two of them in a row, as a browser reads `\\` as `//`.
           '!"#$%&\'()*+,-.:;<=>?@[]^_`{|}~'.chars.map { |char| "&##{char.ord};" } +
           '.*_+`<>()[]{}#!:|"\'$=-~'.chars.map { |char| "\\#{char}" } +
           # Hard line breaks, and block markers after them.
           ["\\\n  ", "  \n  ", "\\\n  \\## 9.9.9", "\\\n  \\# b", "\\\n  \\> b", "\\\n  1\\. b", "\\\n  \\- b",
            "\\\n  \\-\\-\\-", "\\\n  \\=\\=\\="]

  # The references that release-please writes at the end of an entry, in each of their
  # forms: the subject's own `(#N)`, the commit, and the issues that the commit closes.
  def references(random, index)
    hash = format('%07x', random.rand(16**7))
    closes = Array.new(random.rand(0..3)) do |number|
      ["[##{number}](https://github.com/Kong/kong-harnesses/issues/#{number})", "[Kong/other##{number}](https://github.com/Kong/other/issues/#{number})",
       "[octo/__sample__##{number}](https://github.com/octo/__sample__/issues/#{number})"].sample(random: random)
    end
    [(" ([##{index}](https://github.com/Kong/kong-harnesses/issues/#{index}))" if random.rand(2).zero?),
     (" ([#{hash}](https://github.com/Kong/kong-harnesses/commit/#{hash}#{'0' * 33}))" if random.rand(4).positive?),
     (", closes #{closes.join(' ')}" unless closes.empty?)].join
  end

  # The page that the export writes must have no link or address, and the text of every
  # piece of code must stay as the site's parser reads it in the source.
  def expect_safe(source, page)
    expect(KongHarnessesChangelogLinks.problems(page)).to be_empty, "#{source.inspect} gave #{page.inspect}"
    expect(code(page)).to eq(described_class.code_of(described_class.parse(source))), "#{source.inspect} gave #{page.inspect}"
  end

  # Random entries from the pieces, half of them with references at the end, with a
  # fixed seed. The export may refuse an entry that it cannot write back, such as raw
  # HTML or a link in a sentence, but its self-check must never find that the writer got
  # an entry wrong.
  it 'keeps code and leaves no link for random entries' do
    random = Random.new(20_261_120)
    refused = Hash.new(0)
    1000.times do |index|
      entry = Array.new(random.rand(1..12)) { pieces.sample(random: random) }.join
      source = section("* #{entry}#{references(random, index) if random.rand(2).zero?}")
      begin
        expect_safe(source, exported(source))
      rescue RuntimeError => e
        raise if e.message.include?('The export would')

        refused[e.message[/\A[^"]*/]] += 1
      end
    end
    expect(refused.values.sum).to be < 500, refused.inspect
  end

  # Entries in the shape that release-please writes, with a subject made of the pieces
  # that can be on one line of a commit subject, and references at the end in each form.
  # The export must keep every one.
  it 'keeps every random release-please entry' do
    subject_pieces = pieces.reject do |piece|
      piece.include?("\n") || piece.match?(/<(?:!--|\/?(?:del|b)>)/) || piece == '~~' || piece.match?(%r{https://(?!github\.com/(?:Kong/kong-harnesses/issues/7|alice)\))})
    end
    random = Random.new(20_261_121)
    300.times do |index|
      # The words of a subject, apart as in a commit subject. The fuzz test above glues them.
      subject = Array.new(random.rand(1..8)) { subject_pieces.sample(random: random) }.join(' ')
      source = section("* **#{%w[cli profile relay].sample(random: random)}:** word #{subject}#{references(random, index)}")
      expect_safe(source, exported(source))
    end
  end

  # The writer is not built for the GFM parser, so the self-check reads what it wrote
  # with the site's parser and refuses what a reader would see differently.
  it 'refuses what the writer gets wrong' do
    allow_any_instance_of(described_class::Writer).to receive(:convert_entity) { |_writer, element, _opts| element.value.char } # rubocop:disable RSpec/AnyInstance
    expect { exported(section('* **cli:** use &#124; between values')) }.to raise_error(/would change what a reader sees/)
    tree = described_class.parse("* **x** y\n")
    tree.children.first.children.first.children.first.children.first.children.clear
    expect { described_class.written("* **** y\n", tree) }.to raise_error(/would change what a reader sees/)
    source = described_class.parse("```sh\nkoha up\n```\n")
    expect { described_class.written("    koha up\n", described_class.parse("    koha up\n"), source) }.to raise_error(/language of a code block/)
  end

  # The check reads the text from a second rendering of the source and lets only the
  # references at the end of an entry go.
  it 'refuses a page that changes the text of the source' do
    source = described_class.parse("* **a:** see [2024](https://example.org) \"b\" ([#1](#{issue})) ([abc1234](#{commit}))\n")
    ["* **a:** see “b”\n", "* **a:** see2024 “b”\n", "* **a:** see 2024 b\n", "* **a:** see 2024 “b” (#1)\n", "* **a:** see 2024\n"].each do |page|
      expect { described_class.written(page, described_class.parse(page), source) }.to raise_error(/change the text that a reader sees near "/), page
    end
    expect(described_class.written("* **a:** see 2024 “b”\n", described_class.parse("* **a:** see 2024 “b”\n"), source)).to eq("* **a:** see 2024 “b”\n")
    # Check B reads each address with its own code, so a page that drops a look-alike
    # reference is refused even if the export took it off.
    ['https://github.com.evil.example/Kong/kong-harnesses/issues/1', 'https://githubXcom/Kong/kong-harnesses/issues/1', "#{issue}?x", "#{issue}#y",
     "#{issue}/x", 'Kong/kong-harnesses/issues/1', 'https://github.com/Kong/other/issues/1'].each do |address|
      fake = described_class.parse("* **a:** see ([#1](#{address}))\n")
      expect { described_class.written("* **a:** see\n", described_class.parse("* **a:** see\n"), fake) }.to raise_error(/change the text that a reader sees near "/), address
    end
    ["([abc9999](#{commit}))", "([abc1234](#{commit})), closes [octo/x#4](https://github.com/octo/y/issues/4)"].each do |tail|
      fake = described_class.parse("* **a:** see #{tail}\n")
      expect { described_class.written("* **a:** see\n", described_class.parse("* **a:** see\n"), fake) }.to raise_error(/change the text that a reader sees near "/), tail
    end
    breaking = described_class.parse("### ⚠ BREAKING CHANGES\n\n* **a:** see ([abc1234](#{commit}))\n")
    page = "### ⚠ BREAKING CHANGES\n\n* **a:** see\n"
    expect { described_class.written(page, described_class.parse(page), breaking) }.to raise_error(/change the text that a reader sees near "/)
  end
end
