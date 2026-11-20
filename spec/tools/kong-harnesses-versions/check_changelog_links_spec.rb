# frozen_string_literal: true

require_relative '../../../tools/kong-harnesses-versions/check-changelog-links'

RSpec.describe KongHarnessesChangelogLinks do
  def entry(text)
    "## 1.0.0\n\n### Features\n\n* #{text}\n"
  end

  describe '.check' do
    [
      ['a character reference in the host and name', '[x](https://github&#46;com/Kong/kong&#45;harnesses)'],
      ['raw HTML with character references', '<a href="https://github&#x2e;com/Kong/kong-harnesses/pull/1">x</a>'],
      ['a tab inside the address', "[x](<https://github.com/Kong/kong-\tharnesses>)"],
      ['a .git suffix', 'clone https://github.com/Kong/kong-harnesses.git'],
      ['repeated slashes', '[x](https://github.com//Kong//kong-harnesses)'],
      ['a git+https address', '[x](git+https://github.com/Kong/kong-harnesses)'],
      ['an scp-like git address', 'clone git@github.com:Kong/kong-harnesses.git'],
      ['an ssh address', 'clone ssh://git@github.com/Kong/kong-harnesses'],
      ['an autolink in capitals', '<HTTPS://GITHUB.COM/KONG/KONG-HARNESSES>'],
      ['a port', '[x](https://github.com:443/Kong/kong-harnesses/pull/1)'],
      ['percent-encoding in the name', '[x](https://github.com/Kong/kong%2Dharnesses)'],
      ['percent-encoding in the host', '[x](https://github%2Ecom/Kong/kong-harnesses)'],
      ['double percent-encoding', '[x](https://github.com/Kong/kong%252Dharnesses)'],
      ['a full-width dot in the host', '[x](https://github．com/Kong/kong-harnesses)'],
      ['backslashes', '[x](https:\\\\github.com\\Kong\\kong-harnesses)'],
      ['an invisible character in the host', "[x](https://git​hub.com/Kong/kong-harnesses)"],
      ['the API address', 'see https://api.github.com/repos/Kong/kong-harnesses/releases'],
      ['the raw file address', '![x](https://raw.githubusercontent.com/Kong/kong-harnesses/main/a.png)'],
      ['an address in a code span', 'see `github.com/Kong/kong-harnesses`'],
      ['an address at the end of a sentence', 'see github.com/Kong/kong-harnesses.']
    ].each do |name, text|
      it "refuses #{name}" do
        expect { described_class.check(entry(text)) }.to raise_error(/internal kong-harnesses repository/)
      end
    end

    [
      ['another host that ends with the same name', 'see https://notgithub.com/Kong/kong-harnesses/help'],
      ['a host that starts with the same name', 'see https://github.com.example.com/Kong/kong-harnesses'],
      ['another repository with a longer name', '[x](https://github.com/Kong/kong-harnesses-plugin)'],
      ['the product name in text', 'run kong-harnesses login once after the upgrade'],
      ['an entry in parentheses', 'use the value from (the migration guide).']
    ].each do |name, text|
      it "accepts #{name}" do
        expect { described_class.check(entry(text)) }.not_to raise_error
      end
    end

    it 'accepts the published changelog data' do
      markdown = JSON.parse(File.read(described_class::DATA_FILE)).fetch('markdown')

      expect { described_class.check(markdown) }.not_to raise_error
    end
  end
end
