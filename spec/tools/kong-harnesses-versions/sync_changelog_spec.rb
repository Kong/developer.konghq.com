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

  def section(body)
    "## 1.0.0\n\n### Features\n\n#{body}\n"
  end

  def code(markdown)
    Nokogiri::HTML5.fragment(KongHarnessesChangelogLinks.html(markdown)).css('code').map { |node| node.text.chomp }
  end

  release_please_changelog = <<~MARKDOWN
    # Changelog

    ## [0.17.1](https://github.com/Kong/kong-harnesses/compare/v0.17.0...v0.17.1) (2026-11-19)


    ### ⚠ BREAKING CHANGES

    * **profile:** run login again after the upgrade


    ### Bug Fixes

    * **profile:** accept plain http for a gateway on loopback ([#417](https://github.com/Kong/kong-harnesses/issues/417)) ([802a984](https://github.com/Kong/kong-harnesses/commit/802a9848c49528cc52bb72365b6100ea68e30183))
    * **ksai:** let autofix change the Go module files
    * **deps:** update Go
    * **docs:** follow the [Claude Code settings](https://code.claude.com/docs/en/settings) {{ unchanged }} {% endraw %}


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

  # Each case gives the source entry and the entry that the page gets. Links go and keep
  # their text, and the text of code stays as it is.
  [
    ['* fix([#1](https://github.com/kong/kong-harnesses/pull/1))', '* fix'],
    ['* see <https://github.com/Kong/kong-harnesses/issues/2>', '* see'],
    ["* see [the issue][issue]\n\n[issue]: https://github.com/Kong/kong-harnesses/issues/4", '* see the issue'],
    ['* see [the PR](https://github.com/Kong/kong-harnesses/pull/5 "title") first', '* see the PR first'],
    ["* see [the PR](<https://github.com/Kong/kong-harnesses/pull/7\t>) first", '* see the PR first'],
    ['* fix (closes [#12](https://github.com/Kong/kong-harnesses/issues/12)) now', '* fix (closes) now'],
    ['* fix, see [c0ffee1](https://github.com/Kong/kong-harnesses/commit/c0ffee1) and [the guide](https://github.com/Kong/kong-harnesses/blob/main/docs/a.md)', '* fix, see and the guide'],
    ['* see [defaced](https://github.com/Kong/kong-harnesses/pull/1)', '* see defaced'],
    ['* see [x](https://github&#46;com/Kong/kong&#45;harnesses) first', '* see x first'],
    ['* use the value from ([the migration guide](https://github.com/Kong/kong-harnesses/blob/main/docs/m.md)).', '* use the value from (the migration guide).'],
    ['* see ![the diagram](https://raw.githubusercontent.com/Kong/kong-harnesses/main/a.png)', '* see the diagram'],
    ["* see ![alt][img]\n\n[img]: https://github.com/Kong/kong-harnesses/a.png", '* see alt'],
    ["* see [x][r]\n\n    [r]: https://github.com/Kong/kong-harnesses", '* see x'],
    ['* released in [2026](https://example.com/release-year)', '* released in 2026'],
    ['* [![badge](https://img.example/x.svg)](https://example.com/evil) entry', '* badge entry'],
    ['* see [a [b] c](https://example.com/x) d', '* see a \\[b\\] c d'],
    ["* see [the\n  guide](https://example.com/g) now", '* see the guide now'],
    ['* use [`profile activate`](/reference/) now', '* use `profile activate` now'],
    ["* use [`profile activate`][] now\n\n[`Profile activate`]: /reference/", '* use `profile activate` now'],
    ["* use [`profile activate`] now\n\n[`profile activate`]: /reference/", '* use `profile activate` now'],
    ["* run `printf 'a  b'`  twice ([#1](https://github.com/Kong/kong-harnesses/pull/1))", "* run `printf 'a  b'` twice"],
    # The release-please preset links an issue number even in a code span.
    ['* run `foo [#123](https://github.com/Kong/kong-harnesses/issues/123)` now', '* run `foo #123` now'],
    # Text that only looks like Markdown stays text, so the writer escapes it.
    ['* literal \\[mode](optional)', '* literal \\[mode\\](optional)'],
    ['* \\![foo](https://example.com) next', '* !foo next'],
    ["* ```\n  [x](https://example.com)", '* &#96;&#96;&#96; x'],
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
    ["* use a\\-\\-b, a\\.\\.\\.b and a\\>\\>b", "* use a\\-\\-b, a\\.\\.\\.b and a\\>\\>b"],
    ["* Before\\\n  \\=\\=\\=", "* Before  \n  \\==="],
    # Kramdown's writer gives a rule as `* * *`, which after a list marker is a rule alone.
    ['* ___', '* ___'],
    # Two backslashes at the end of a line are a line break.
    ['* in C:\\\\', '* in C:&#92;'],
    ['* see **[https://example.com](https://example.com)** now', '* see now'],
    # A link whose text is its own web or mail address goes, but a link to a file keeps
    # its text. Quotes and brackets that held only a removed link go with it.
    ['* see [docs/release.md](docs/release.md) now', '* see docs/release.md now'],
    ['* see [CHANGELOG.md](CHANGELOG.md)', '* see CHANGELOG.md'],
    ['* see "<https://example.com/a>" word', '* see word'],
    ["* see <profile>'<https://example.com/a>'.", '* see \\<profile>.'],
    ["* x\"q\"'<https://example.com/y>'\"q\" y", '* x”q”“q” y'],
    ['* see <https://example.com/a>. Then', '* see. Then'],
    ['* mail <mailto:a@example.com> or [b@example.com](mailto:b@example.com) now', '* mail or now'],
    ['* run profile get <profile> or `profile get <profile>`', '* run profile get \\<profile> or `profile get <profile>`'],
    ['* run profile get \\<profile>', '* run profile get \\<profile>'],
    # A placeholder at the start of a line is text too.
    ['* <profile> now works ([#1](https://github.com/Kong/kong-harnesses/issues/1))', '* \\<profile> now works'],
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
    # Two lists of the same kind with only an empty list between them become one.
    ["* a\n\n3. \n\n* b", "* a\n* b"],
    # A line of code that starts with a number reads back as code.
    ["* the value `1.2\n  2.1.3` here", "* the value `1.2\n  2.1.3` here"],
    ['* a ` [x](https://github.com/Kong/./kong-harnesses) `` d', '* a &#96; x &#96;&#96; d'],
    # Code spans as kramdown pairs them, also across the lines of a paragraph.
    ['* ``<a>``` x', '* `<a>`&#96; x'],
    # Two code spans with nothing between them become one, as no Markdown can write them.
    ['* a ``x```y` b', '* a `xy` b'],
    # The site's table parser pairs an escaped backtick with the one of a code span.
    ['* \\`a `x|y` b', '* &#96;a `x|y` b'],
    ["* run `curl\n  https://example.com/x` now", "* run `curl\n  https://example.com/x` now"],
    ['* a \\\\` https://example.com/x ` end', '* a \\\\``  https://example.com/x  `` end'],
    ["* **cli:** run this after the upgrade:\n\n>     kong-harnesses profile get <profile> --url [docs](http://h/x)",
     "* **cli:** run this after the upgrade:\n\n>     kong-harnesses profile get <profile> --url [docs](http://h/x)"]
  ].each do |entry, expected|
    it "exports #{entry.inspect}" do
      expect(exported(section(entry))).to eq(section(expected))
    end
  end

  # Only the parser can say where an address in text ends, and it gives no node for one,
  # so the export refuses such an entry and names it rather than guess.
  [
    '* see https://github.com/Kong/kong-harnesses/issues/3 first',
    '* see <HTTPS://GitHub.com/Kong/kong-harnesses/issues/2> now',
    '* see (https://example.com/foo) ok',
    '* see https://exa**mple**.com/a',
    '* literal \\[foo](https://example.com) next',
    '* x ` <profile> https://example.com/a ` y',
    '* **cli:** https://example.org"restart now" after setup.',
    '* see https://example.com/a&#133;word now',
    '* see https://example.com/a…word now',
    *%w[&#9; &#10; &#11; &#12; &#13; &#32;].map { |entity| "* see https://example.com/a#{entity}word now" },
    "* go https://example.com/a\u00a0word",
    "* see 'https://example.com/a' word",
    '* fix https://example.com/a’s crash'
  ].each do |entry|
    it "refuses the address in #{entry.inspect}" do
      expect { exported(section(entry)) }.to raise_error(/an address in the text of "/)
    end
  end

  # A removed link right before a word would take what it held out of the sentence.
  [
    "* fix [#1](https://github.com/Kong/kong-harnesses/issues/1)'s crash",
    '* see <https://example.com/a>word',
    "* see <https://example.com/a>'s page"
  ].each do |entry|
    it "refuses the removed link in #{entry.inspect}" do
      expect { exported(section(entry)) }.to raise_error(/a link right before a word in "/)
    end
  end

  it 'changes no text inside a code block' do
    [
      "* set it:\n\n  ```toml\n  [mode]: automatic\n  see [x](https://example.com/x) and <profile>\n\n\n\n### Documentation\n* **ci:** [#1]\n  ```",
      "* ~~~sh\n  echo 'https://example.com/docs'\n  ~~~",
      "* or:\n\n      [mode]: automatic\n\n      ## not a heading <b>",
      "* entry\n\n      code\n  [x](https://example.com)\n  https://example.com",
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
    expect { exported(section("* a\u0000b")) }.to raise_error(/NUL/)
  end

  it 'leaves out the repository tooling scopes, also with a nested scope, but keeps an upgrade step' do
    expect(exported("## 1.0.0\n\n### Bug Fixes\n\n* **deps(actions):** bump\n* **ci(release):** retry\n* **cli(help):** fix\n"))
      .to eq("## 1.0.0\n\n### Bug Fixes\n\n* **cli(help):** fix\n")
    expect(exported("## 1.0.0\n\n### ⚠ BREAKING CHANGES\n\n* **deps:** install Go 1.30 first\n\n### Bug Fixes\n\n* **deps:** update Go\n"))
      .to eq("## 1.0.0\n\n### ⚠ BREAKING CHANGES\n\n* **deps:** install Go 1.30 first\n")
  end

  it 'drops an entry that held only a reference, and a section with no entry left' do
    expect(exported("## 1.0.0\n\n### Features\n\n* [#12](https://github.com/Kong/kong-harnesses/issues/12)\n* add\n\n### Bug Fixes\n\n* [#13](https://github.com/Kong/kong-harnesses/issues/13)\n"))
      .to eq("## 1.0.0\n\n### Features\n\n* add\n")
  end

  it 'publishes only the sections of published releases' do
    changelog = "preamble\n\n## 0.19.0\n\n### Features\n\n* later\n\n## 0.18.0-rc.2\n\n### Features\n\n* not out\n\n" \
                "## [0.18.0-rc.1](x)\n\n### Features\n\n* candidate\n\n## 0.17.1\n\n### Features\n\n* add\n"
    expect(exported(changelog, %w[0.18.0-rc.1 0.17.1])).to eq("## 0.17.1\n\n### Features\n\n* add\n")
    # 0.18.0 never shipped, so its candidate stays out even below a later release.
    expect(exported(changelog, %w[0.18.0-rc.1 0.17.1 0.19.0])).to eq("## 0.19.0\n\n### Features\n\n* later\n\n## 0.17.1\n\n### Features\n\n* add\n")
    expect(exported("## 0.18.0\n\n### Features\n\n* final\n\n## [0.18.0-rc.1](x)\n\n### Features\n\n* candidate\n", %w[0.18.0-rc.1 0.18.0]))
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
  # land in code.
  pieces = ['[x](https://example.com/pull/1)', '[#2](https://github.com/Kong/kong-harnesses/issues/2)',
            '`a <b> https://example.com/c`', '``d`e``', '`', '<profile>', '|', '[', ']', '(', ')',
            '**', '_', '~~', '~~~', '```', '    ', "\n", "\n\n", '> ', '* ', '1. ', '# ', 'https://example.com/z',
            '<https://example.com/q>', '![i](https://example.com/i.png)', '[r]', "\n[r]: https://example.com/pull/3\n",
            'word', ' ', "it's", '"q"', '--', '&amp;', '{: .x}', ':', '-',
            '**[https://example.com](https://example.com)**',
            '<!-- note -->', '<del>x</del>', '<b>', '</b>',
            # Links next to quotes, and list starts. An address in text is refused, so the
            # table above has those cases.
            "'<https://example.com/y>'", '"[#4](https://github.com/Kong/kong-harnesses/issues/4)"',
            "\n3. ", "\n<name> "] +
           # Every ASCII punctuation character as an entity, and every character that the
           # GFM parser escapes with a backslash. A slash and a backslash are left out,
           # because the check refuses two of them in a row, as a browser reads `\\` as `//`.
           '!"#$%&\'()*+,-.:;<=>?@[]^_`{|}~'.chars.map { |char| "&##{char.ord};" } +
           '.*_+`<>()[]{}#!:|"\'$=-~'.chars.map { |char| "\\#{char}" } +
           # Hard line breaks, and block markers after them.
           ["\\\n  ", "  \n  ", "\\\n  \\## 9.9.9", "\\\n  \\# b", "\\\n  \\> b", "\\\n  1\\. b", "\\\n  \\- b",
            "\\\n  \\-\\-\\-", "\\\n  \\=\\=\\="]

  # The page that the export writes must have no link or address, and the text of every
  # piece of code must stay as the site's parser reads it in the source.
  def expect_safe(source, page)
    source_code = described_class.code_of(described_class.parse(source)).map do |value|
      described_class::PRESET_LINKS.reduce(value) { |text, link| text.gsub(link, '\1') }
    end
    expect(KongHarnessesChangelogLinks.problems(page)).to be_empty, "#{source.inspect} gave #{page.inspect}"
    # Two code spans with nothing between them become one.
    expect(code(page).join).to eq(source_code.join), "#{source.inspect} gave #{page.inspect}"
  end

  # Random entries from the pieces, with a fixed seed. The export may refuse an entry
  # that it cannot write back, such as raw HTML, but its self-check must never find
  # that the writer got an entry wrong.
  it 'keeps code and leaves no link for random entries' do
    random = Random.new(20_261_120)
    refused = Hash.new(0)
    1000.times do
      source = section("* #{Array.new(random.rand(1..12)) { pieces.sample(random: random) }.join}")
      begin
        expect_safe(source, exported(source))
      rescue RuntimeError => e
        raise if e.message.include?('The export would')

        refused[e.message] += 1
      end
    end
    expect(refused.values.sum).to be < 400, refused.inspect
  end

  # Entries in the shape that release-please writes, with a subject made of the pieces
  # that can be on one line of a commit subject. The export must keep every one.
  it 'keeps every random release-please entry' do
    # release-please writes links, not an address in text, and the export refuses both
    # that and a link in quotes right before a word.
    subject_pieces = pieces.reject do |piece|
      piece.include?("\n") || piece.match?(/<(?:!--|\/?(?:del|b)>)/) || piece == '~~' || piece.match?(/\A(?:<?https:|['"])/)
    end
    random = Random.new(20_261_121)
    300.times do |index|
      # The words of a subject, apart as in a commit subject. The fuzz test above glues them.
      subject = Array.new(random.rand(1..8)) { subject_pieces.sample(random: random) }.join(' ')
      hash = format('%07x', random.rand(16**7))
      source = section("* **#{%w[cli profile relay].sample(random: random)}:** word #{subject} " \
                       "([##{index}](https://github.com/Kong/kong-harnesses/issues/#{index})) " \
                       "([#{hash}](https://github.com/Kong/kong-harnesses/commit/#{hash}))")
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

  # The check reads the text from a second rendering, so it does not share the rules of
  # the export: only a whole link that is a reference or its own address, and the
  # brackets and quotes next to it, can go.
  it 'refuses a page that leaves out or joins words of the source' do
    source = described_class.parse("* see [https://example.com/a](https://example.com/a) and [the docs](https://example.com/d) \"b\"\n")
    ["* see the docs “b”\n", "* seeand the docs “b”\n", "* see and “b”\n", "* see and the docs b\n"].each do |page|
      expect { described_class.written(page, described_class.parse(page), source) }.to raise_error(/leave out text/), page
    end
    expect(described_class.written("* see and the docs “b”\n", described_class.parse("* see and the docs “b”\n"), source)).to eq("* see and the docs “b”\n")
  end
end
