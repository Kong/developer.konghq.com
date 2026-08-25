# frozen_string_literal: true

RSpec.describe 'how-tos/validations/unauthorized-check/snippet.md' do
  let(:template) { '{% include how-tos/validations/unauthorized-check/snippet.md url=config.url headers=config.headers %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid bash command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end
  end

  context 'no headers' do
    let(:config) { { 'url' => '/anything' } }

    include_examples 'a valid bash command'

    it 'renders the exact curl command' do
      expect(rendered).to eq(<<~MD)
        ```bash
        #{'curl -i /anything '}
        ```
      MD
    end
  end

  context 'a single header' do
    let(:config) { { 'url' => '/anything', 'headers' => ['apikey:another_key'] } }

    include_examples 'a valid bash command'

    it 'renders the header on its own continuation line' do
      expect(rendered).to eq(<<~MD)
        ```bash
        curl -i /anything \\
             -H "apikey:another_key"
        ```
      MD
    end
  end

  context 'multiple headers, exercising the forloop.last continuation (synthetic)' do
    let(:config) { { 'url' => '/anything', 'headers' => ['Accept: application/json', 'apikey: test-key'] } }

    include_examples 'a valid bash command'

    it 'chains the header lines with backslash continuations except the last' do
      expect(rendered).to eq(<<~MD)
        ```bash
        curl -i /anything \\
             -H "Accept: application/json"\\
             -H "apikey: test-key"
        ```
      MD
    end
  end
end
