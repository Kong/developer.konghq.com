# frozen_string_literal: true

# The base case (no base_url) is adapted from the real {% validation codex %} block in
# app/_how-tos/ai-gateway/use-codex-with-ai-gateway.md. That's the only real-doc usage of
# this validation, and it never sets `base_url`, so the base_url branch is synthetic, built
# directly from the snippet.md logic, to get full branch coverage.
RSpec.describe 'how-tos/validations/codex/snippet.md' do
  let(:validations_config) do
    [{ 'id' => 'codex', 'command' => 'codex', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:config) { Jekyll::Drops::Validations::Codex.new(id: 'codex', yaml: yaml) }
  let(:template) { '{% include how-tos/validations/codex/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered, lang: 'sh') }

  shared_examples 'a valid shell command' do
    it 'renders syntactically valid shell' do
      validate_bash_syntax!(code)
    end
  end

  context 'with no base_url (use-codex-with-ai-gateway.md)' do
    let(:yaml) { { 'model' => 'gpt-5.4', 'prompt' => 'Hello' } }

    include_examples 'a valid shell command'

    it 'renders the base command with no env export and no leading blank line' do
      expect(rendered).to eq(<<~MD)
        ```sh
        codex --model "gpt-5.4"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Hello
        ```
      MD
    end
  end

  context 'with base_url (synthetic)' do
    let(:yaml) { { 'model' => 'gpt-5.4', 'prompt' => 'Hello', 'base_url' => 'http://localhost:9000/codex' } }

    include_examples 'a valid shell command'

    it 'renders the OPENAI_BASE_URL export before the base command' do
      expect(rendered).to eq(<<~MD)
        ```sh
        export OPENAI_BASE_URL=http://localhost:9000/codex

        codex --model "gpt-5.4"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Hello
        ```
      MD
    end
  end
end
