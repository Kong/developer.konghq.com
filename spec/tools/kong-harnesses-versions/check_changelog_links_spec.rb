# frozen_string_literal: true

require_relative '../../../tools/kong-harnesses-versions/check-changelog-links'

RSpec.describe KongHarnessesChangelogLinks do
  def entry(text)
    "## 1.0.0\n\n### Features\n\n* #{text}\n"
  end

  describe '.check' do
    [
      ['a link to any address', '[x](https://example.com/a)'],
      ['a link after unequal backtick runs', 'a ` [x](https://github.com/Kong/./kong-harnesses) `` d'],
      ['a link with a ../ segment', '[x](https://github.com/Kong/../Kong/kong-harnesses)'],
      ['a link to a renamed repository', '[x](https://github.com/Kong/agent-auth-cli)'],
      ['a link to another GitHub host', '[x](https://github.dev/Kong/kong-harnesses)'],
      ['an image', 'a ` <img src="https://github.com/Kong/kong-harnesses/a.png"> `` d'],
      ['a link from an indented definition', "see [x][r]\n\n    [r]: //github.com/Kong/./kong-harnesses"],
      ['a link from a definition in a block quote', "see [x][r]\n\n> [r]: //github.com/Kong/./kong-harnesses"],
      ['a link with character references', '[x](https://github&#46;com/Kong/kong&#45;harnesses)'],
      ['raw HTML with an address', '<a href="https://github&#x2e;com/Kong/kong-harnesses/pull/1">x</a>'],
      ['a meta refresh', '<meta http-equiv="refresh" content="0; url=https://github.com/Kong/kong-harnesses">'],
      ['an SVG link', '<svg><a xlink:href="https://github.com/Kong/kong-harnesses"><text>x</text></a></svg>'],
      ['an attribute list on a span', '*x*{: title="x" data-x="https://github.com/Kong/kong-harnesses"}'],
      ['an autolink in capitals', '<HTTPS://GITHUB.COM/KONG/KONG-HARNESSES>'],
      ['a scheme-relative address in text', 'see //github.com/Kong/kong-harnesses/x now'],
      ['an ssh address in text', 'accept ssh://user@host targets'],
      ['an scp-like git address', 'clone git@github.com:Kong/kong-harnesses.git'],
      ['a full-width dot in the host', 'see github．com/Kong/kong-harnesses'],
      ['percent-encoding in the name', 'see github.com/Kong/kong%252Dharnesses'],
      ['an invisible character in the host', "see git​hub.com/Kong/kong-harnesses"],
      ['the repository in a code span', 'run `go install github.com/Kong/kong-harnesses/cmd/x`'],
      ['the repository at the end of a sentence', 'see github.com/Kong/kong-harnesses.'],
      ['an HTML comment', '<!-- note -->'],
      ['a footnote', "see [^1]\n\n[^1]: a note"],
      ['the repository split by bold', 'see github.com/**Kong**/kong-harnesses'],
      ['the repository split by a code span', 'see `github.com`/Kong/kong-harnesses'],
      ['an address split by bold', 'see https:**//**example.com']
    ].each do |name, text|
      it "refuses #{name}" do
        expect { described_class.check(entry(text)) }.to raise_error(/link or an address/)
      end
    end

    [
      ['another host that ends with the same name', 'see `notgithub.com/Kong/kong-harnesses/help`'],
      ['a host that starts with the same name', 'see `github.com.example.com/Kong/kong-harnesses`'],
      ['another repository with a longer name', 'see `github.com/Kong/kong-harnesses-plugin`'],
      ['the host and the path in separate paragraphs', "see github.com\n\n  then Kong/kong-harnesses"],
      ['an address in a code span', 'run `curl https://example.com/a`'],
      ['the product name in text', 'run kong-harnesses login once after the upgrade'],
      ['an entry in parentheses', 'use the value from (the migration guide).']
    ].each do |name, text|
      it "accepts #{name}" do
        expect { described_class.check(entry(text)) }.not_to raise_error
      end
    end

    # The spec loads the site plugins, which highlight code blocks with Shiki, so these
    # cases give the HTML that kramdown renders for the sync job.
    it 'accepts the language of a code block, and no other class' do
      expect(described_class.html_problems('<pre><code class="language-sh">x</code></pre>')).to be_empty
      expect(described_class.html_problems('<code class="x">x</code>')).to eq(['the attribute class on <code>'])
    end

    it 'accepts the published changelog data' do
      markdown = JSON.parse(File.read(described_class::DATA_FILE)).fetch('markdown')

      expect { described_class.check(markdown) }.not_to raise_error
    end
  end
end
