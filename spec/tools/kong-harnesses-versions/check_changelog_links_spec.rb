# frozen_string_literal: true

require_relative '../../../tools/kong-harnesses-versions/check-changelog-links'

RSpec.describe KongHarnessesChangelogLinks do
  before { stub_const('ENV', ENV.to_h.merge('KONG_HARNESSES_RELEASES_REPO' => 'example/sample-tool')) }

  describe '.repo' do
    [nil, '', 'sample-tool', 'example/sample-tool/x', 'example/sample tool', 'example/..', 'example/.', '../sample-tool'].each do |value|
      it "refuses #{value.inspect} and names the variable" do
        stub_const('ENV', ENV.to_h.merge('KONG_HARNESSES_RELEASES_REPO' => value).compact)
        expect { described_class.check(entry('add')) }.to raise_error(/KONG_HARNESSES_RELEASES_REPO/)
      end
    end
  end

  def entry(text)
    "## 1.0.0\n\n### Features\n\n* #{text}\n"
  end

  describe '.check' do
    [
      ['a link to any address', '[x](https://example.com/a)'],
      ['a link after unequal backtick runs', 'a ` [x](https://github.com/example/./sample-tool) `` d'],
      ['a link with a ../ segment', '[x](https://github.com/example/../example/sample-tool)'],
      ['a link to a renamed repository', '[x](https://github.com/example/old-tool)'],
      ['a link to another GitHub host', '[x](https://github.dev/example/sample-tool)'],
      ['an image', 'a ` <img src="https://github.com/example/sample-tool/a.png"> `` d'],
      ['a link from an indented definition', "see [x][r]\n\n    [r]: //github.com/example/./sample-tool"],
      ['a link from a definition in a block quote', "see [x][r]\n\n> [r]: //github.com/example/./sample-tool"],
      ['a link with character references', '[x](https://github&#46;com/example/sample&#45;tool)'],
      ['raw HTML with an address', '<a href="https://github&#x2e;com/example/sample-tool/pull/1">x</a>'],
      ['a meta refresh', '<meta http-equiv="refresh" content="0; url=https://github.com/example/sample-tool">'],
      ['an SVG link', '<svg><a xlink:href="https://github.com/example/sample-tool"><text>x</text></a></svg>'],
      ['an attribute list on a span', '*x*{: title="x" data-x="https://github.com/example/sample-tool"}'],
      ['an autolink in capitals', '<HTTPS://GITHUB.COM/EXAMPLE/SAMPLE-TOOL>'],
      ['a scheme-relative address in text', 'see //github.com/example/sample-tool/x now'],
      ['an ssh address in text', 'accept ssh://user@host targets'],
      ['an scp-like git address', 'clone git@github.com:example/sample-tool.git'],
      ['a full-width dot in the host', 'see github．com/example/sample-tool'],
      ['percent-encoding in the name', 'see github.com/example/sample%252Dtool'],
      ['an invisible character in the host', "see git​hub.com/example/sample-tool"],
      ['the repository in a code span', 'run `go install github.com/example/sample-tool/cmd/x`'],
      ['the repository at the end of a sentence', 'see github.com/example/sample-tool.'],
      ['an HTML comment', '<!-- note -->'],
      ['a footnote', "see [^1]\n\n[^1]: a note"],
      ['the repository split by bold', 'see github.com/**example**/sample-tool'],
      ['the repository split by a code span', 'see `github.com`/example/sample-tool'],
      ['an address split by bold', 'see https:**//**example.com'],
      ['a www address', 'see www.example.org now'],
      ['a mail address', 'mail me@example.org now'],
      ['a mail address with no dot', 'mail me@localhost now'],
      ['a mailto address', 'write to mailto:me now'],
      ['an xmpp address', 'chat on xmpp:me now'],
      # Each character that shows nothing by default goes before the checks read the text.
      ['a tag character in a host', "see www\u{e0020}.example.com"],
      ['a function application in a scheme', "see https:/\u2061/evil.example"],
      ['a line separator in a host', "see ww\u2028w.evil.example"],
      ['an annotation character in the repository', "run `github.com/example\ufff9/sample-tool`"],
      ['a hieroglyph format control in the repository', "run `github.com/example\u{13430}/sample-tool`"],
      ['the repository in tag characters after a black flag', "see \u{1f3f4}#{'see github.com/example/sample-tool'.chars.map { |char| (char.ord + 0xe0000).chr(Encoding::UTF_8) }.join}\u{e007f}"],
      ['a vowel separator in a mail address', "mail bob\u180e@evil.example"],
      ['a grapheme joiner in the repository', "run `github.com/example\u034f/sample-tool`"],
      ['a variation selector in a host', "see www\ufe0f.example.com"],
      ['a . segment in the repository', 'run `github.com/example/./sample-tool`'],
      ['a .. segment in a GitHub address', 'run `github.com/x/../example/sample-tool`'],
      ['a client that the docs do not cover yet', 'set up **Codex** too']
    ].each do |name, text|
      it "refuses #{name}" do
        expect { described_class.check(entry(text)) }.to raise_error(/in release 1\.0\.0, section Features, entry 1 on the page/)
      end
    end

    # GitHub names are not case-sensitive, so the address is refused in any letter case
    # of the secret and of the text.
    ['run `go install github.com/example/sample-tool/cmd/x`', 'see `github.com/EXAMPLE/sample-TOOL`'].each do |text|
      it "refuses #{text.inspect} with the repository in another letter case" do
        stub_const('ENV', ENV.to_h.merge('KONG_HARNESSES_RELEASES_REPO' => 'Example/SAMPLE-tool'))
        expect { described_class.check(entry(text)) }.to raise_error(/releases repository/)
      end
    end

    [
      ['another host that ends with the same name', 'see `notgithub.com/example/sample-tool/help`'],
      ['a host that starts with the same name', 'see `github.com.example.com/example/sample-tool`'],
      ['another repository with a longer name', 'see `github.com/example/sample-tool-plugin`'],
      ['the host and the path in separate paragraphs', "see github.com\n\n  then example/sample-tool"],
      ['an address in a code span', 'run `curl https://example.com/a`'],
      ['the product name in text', 'run kong-harnesses login once after the upgrade'],
      ['an entry in parentheses', 'use the value from (the migration guide).'],
      ['a user name', 'thanks to @bob for the report'],
      ['a scoped package name', 'bump @types/node'],
      ['a mail address in a code span', 'run `git config user.email me@example.org`'],
      ['dots in a GitHub address that are no segment', 'see `github.com/a/b/compare/v1...v2`'],
      ['the flag of a region', "go to \u{1f3f4}\u{e0067}\u{e0062}\u{e0073}\u{e0063}\u{e0074}\u{e007f} now"],
      ['a soft hyphen, a zero width joiner and a word joiner', "a\u00adb c\u200dd e\u2060f"],
      ['a strikethrough', 'a ~~gone~~ word'],
      ['one variation selector right after an emoji', "a \u2764\ufe0f and 1\ufe0f\u20e3"],
      ['a word that only contains the name of such a client', 'read a pipe or an epic']
    ].each do |name, text|
      it "accepts #{name}" do
        expect { described_class.check(entry(text)) }.not_to raise_error
      end
    end

    it 'reads the repository through a format character' do
      ["\ufff9", "\u{13430}", "\u2061"].each do |format|
        expect(described_class.problems("run `github.com/example#{format}/sample-tool`")).to include(a_string_starting_with('the releases repository')), format.inspect
      end
    end

    it 'names the backtick fix for a value that reads as a mail address' do
      expect { described_class.check(entry('use go@1.21 now')) }.to raise_error(/`go@1\.21` can go in backticks/)
    end

    ["\u0001", "\u007f", '&#1;', '&#x2;', '&#x7f;', "\u202e", '&#x2066;', '&#xfffe;', "\u{e0041}\u{e0042}", '&#xE0041;',
     "\u{e0067}\u{e007f}", "\u2061", "\ufff9", '&#xfffb;', "\u{13430}", '&#x1343f;', "\u{1f600}\u{e0100}", '&#xE0100;', "a\ufe0f", "\u3164",
     "\uffa0", "\ufff0", "\u180b", "\u034f", "\u2028", '&#x2029;', "\u00ad\u{1f3f4}\u{e0075}\u{e0073}\u{e0063}\u{e0061}\u{e007f}"].each do |control|
      it "refuses the hidden character #{control.inspect}" do
        expect { described_class.check(entry("fix it (#{control}) now")) }.to raise_error(/a hidden code point/)
      end
    end

    it 'refuses a control character in an attribute' do
      expect(described_class.html_problems("<h2 id=\"a\u0002b\">1.0.0</h2>")).to include('a hidden code point in the heading of release 1.0.0')
    end

    # The spec loads the site plugins, which highlight code blocks with Shiki, so these
    # cases give the HTML that kramdown renders for the sync job.
    it 'accepts a language that the site highlights, and no other class' do
      expect(described_class.html_problems('<pre><code class="language-sh">x</code></pre>')).to be_empty
      expect(described_class.html_problems('<pre><code class="language-text">x</code></pre>')).to be_empty
      expect(described_class.html_problems('<pre><code class="language-rust">x</code></pre>')).to match([a_string_starting_with('an attribute that plain text markup does not have')])
      expect(described_class.html_problems('<code class="x">x</code>')).to match([a_string_starting_with('an attribute that plain text markup does not have')])
    end

    # GitHub masks only the exact text of the secret, so an error that quoted the entry
    # would show the repository in another letter case in the job log.
    it 'names the place of a refused entry and none of its text' do
      markdown = "## 1.0.0 (2026-01-01)\n\n### Features\n\n* add\n\n### Bug Fixes\n\n* fix\n* see `github.com/EXAMPLE/SAMPLE-TOOL` and <SAMPLE-TOOL>x</SAMPLE-TOOL>\n"
      expect { described_class.check(markdown) }.to raise_error(/in release 1\.0\.0, section Bug fixes, entry 2/) { |error| expect(error.message).not_to match(/sample-tool|see /i) }
    end

    # The page that the sync spec's release-please fixture gives, with an older release.
    page = <<~MARKDOWN
      ## 0.17.1 (2026-11-19)

      ### ⚠ BREAKING CHANGES

      * **profile:** run login again after the upgrade

      ### Bug Fixes

      * **profile:** accept plain http for a gateway on loopback
      * **docs:** follow the Claude Code settings

      ## 0.17.0 (2026-11-18)

      ### Features

      * **cli:** add a flag
    MARKDOWN

    [
      ['a hidden code point in an entry', page.sub('follow the', "follow‮ the"),
       'a hidden code point in release 0.17.1, section Bug fixes, entry 2 on the page'],
      ['a bad heading of the second release', page.sub('## 0.17.0 (2026-11-18)', '## 0.17.0 (2026-11-18) a@b'),
       'an address in the heading of release 0.17.0 '],
      ['a bad heading of the second section', page.sub('### Bug Fixes', "### Bug Fixes\n{: data-x=\"1\"}"),
       'an attribute that plain text markup does not have in the heading of section Bug fixes of release 0.17.1'],
      ['a bad heading of an unknown section', page.sub('### Bug Fixes', '### Other a@b'),
       'an address in the heading of section 2 of release 0.17.1 '],
      ['an entry of an unknown section', page.sub('### Bug Fixes', '### Other').sub('follow the', 'follow a@b the'),
       'an address in release 0.17.1, section 2, entry 2 on the page '],
      ['a second release with the version of an earlier one', page.sub('## 0.17.0 (2026-11-18)', '## 0.17.1 (2026-11-18)'),
       'a second release 0.17.1 at release heading 2'],
    ].each do |name, markdown, place|
      it "names the place of #{name}" do
        expect { described_class.check(markdown) }.to raise_error(RuntimeError, /#{Regexp.escape(place)}/)
      end
    end

    it 'reads every language of the Shiki plugin and refuses an entry or a form that it cannot read' do
      shiki = <<~JS
        langs: [
          "yaml", 'fish',
          "json"
        ],
        const languageMap = { bash: "fish", 'sh': 'fish',
            console: "fish", cef: "text" };
        const language = languageMap[lang] || lang;
      JS
      expect(described_class.languages_in(shiki)).to eq(Set['yaml', 'fish', 'json', 'bash', 'sh', 'console', 'cef', 'text'])
      expect { described_class.languages_in(shiki.sub('"json"', '"json" // the API')) }.to raise_error(/cannot read: "json" \/\/ the API/)
      expect { described_class.languages_in(shiki.sub('console: "fish"', 'console: fishLanguage')) }.to raise_error(/cannot read: console: fishLanguage/)
      # A map value that Shiki does not load would stop the site build.
      expect { described_class.languages_in(shiki.sub('cef: "text"', 'cef: "zig"')) }.to raise_error(/cannot read: cef: "zig"/)
      expect { described_class.languages_in(shiki.sub("\"json\"\n]", '"json"].concat(["go"])')) }.to raise_error(/no list|cannot read/)
      expect { described_class.languages_in("#{shiki}other: { langs: [\"c\"] },") }.to raise_error(/more than one list/)
      expect { described_class.languages_in('langs: [],') }.to raise_error(/empty list|no list/)
      expect(described_class.languages).to include('yaml', 'go', 'bash', 'text')
    end

    it 'accepts the published changelog data' do
      markdown = JSON.parse(File.read(described_class::DATA_FILE)).fetch('markdown')

      expect { described_class.check(markdown) }.not_to raise_error
    end
  end
end
