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
    ['* see <HTTPS://GitHub.com/Kong/kong-harnesses/issues/2> now', '* see now'],
    ['* see https://github.com/Kong/kong-harnesses/issues/3 first', '* see first'],
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
    ['* see (https://example.com/foo) ok', '* see ok'],
    ['* see https://example.com/a_(b) ok', '* see ok'],
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
    ['* literal \\[foo](https://example.com) next', '* literal \\[foo\\] next'],
    ['* \\![foo](https://example.com) next', '* !foo next'],
    ["* ```\n  [x](https://example.com)", '* \\`\\`\\` x'],
    ['* accept values with a | delimiter', '* accept values with a \\| delimiter'],
    ['* run profile get <profile> or `profile get <profile>`', '* run profile get \\<profile> or `profile get <profile>`'],
    ['* run profile get \\<profile>', '* run profile get \\<profile>'],
    ['* x ` <b> https://example.com/a ` y', '* x \\` \\<b> \\` y'],
    ['* a ` [x](https://github.com/Kong/./kong-harnesses) `` d', '* a \\` x \\`\\` d'],
    # Code spans as kramdown pairs them, also across the lines of a paragraph.
    ['* ``<a>``` x', '* `<a>`\\` x'],
    ["* run `curl\n  https://example.com/x` now", "* run `curl\n  https://example.com/x` now"],
    ['* a \\\\` https://example.com/x ` end', '* a \\\\``  https://example.com/x  `` end'],
    ["* **cli:** run this after the upgrade:\n\n>     kong-harnesses profile get <profile> --url [docs](http://h/x)",
     "* **cli:** run this after the upgrade:\n\n>     kong-harnesses profile get <profile> --url [docs](http://h/x)"]
  ].each do |entry, expected|
    it "exports #{entry.inspect}" do
      expect(exported(section(entry))).to eq(section(expected))
    end
  end

  it 'changes no text inside a code block' do
    [
      "* set it:\n\n  ```toml\n  [mode]: automatic\n  see [x](https://example.com/x) and <profile>\n\n\n\n### Documentation\n* **ci:** [#1]\n  ```",
      "* ~~~sh\n  echo 'https://example.com/docs'\n  ~~~",
      "* or:\n\n      [mode]: automatic\n\n      ## not a heading <b>",
      "* entry\n\n      code\n  [x](https://example.com)\n  https://example.com",
      "* run this:\n  ```sh\n  kong-harnesses login\n  ```"
    ].each do |entry|
      expect(code(exported(section(entry)))).to eq(code(section(entry)))
    end
  end

  it 'refuses what it cannot write back safely' do
    expect { exported(section("* see [^1] now\n\n[^1]: a note")) }.to raise_error(/footnote/)
    expect { exported(section('<div>x</div>')) }.to raise_error(/raw HTML/)
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

  # Random entries from pieces of Markdown that earlier reviews found hard, with a fixed
  # seed. The page that the export writes must have no link or address, and the text of
  # every piece of code must stay as the site's parser reads it in the source.
  it 'keeps code and leaves no link for random entries' do
    # The addresses are on another host, because the repository's address in code stops
    # the sync by design, and a piece can land in code.
    pieces = ['[x](https://example.com/pull/1)', '[#2](https://github.com/Kong/kong-harnesses/issues/2)',
              '`a <b> https://example.com/c`', '``d`e``', '`', '<profile>', '|', '\\[', '\\`', '\\!', '[', ']', '(', ')',
              '**', '_', '~~', '~~~', '```', '    ', "\n", "\n\n", '> ', '* ', '1. ', '# ', 'https://example.com/z',
              '<https://example.com/q>', '![i](https://example.com/i.png)', '[r]', "\n[r]: https://example.com/pull/3\n",
              'word', ' ', "it's", '"q"', '--', '&amp;', '{: .x}', ':', '-']
    random = Random.new(20_261_120)
    300.times do
      source = section("* #{Array.new(random.rand(1..12)) { pieces.sample(random: random) }.join}")
      page = begin
        exported(source)
      rescue RuntimeError
        next
      end
      source_code = described_class.code_of(described_class.parse(source)).map do |value|
        described_class::PRESET_LINKS.reduce(value) { |text, link| text.gsub(link, '\1') }
      end

      expect(KongHarnessesChangelogLinks.problems(page)).to be_empty, "#{source.inspect} gave #{page.inspect}"
      expect(code(page)).to eq(source_code), "#{source.inspect} gave #{page.inspect}"
    end
  end
end
