# frozen_string_literal: true

RSpec.describe 'how-tos/validations/gemini/snippet.md' do
  let(:validations_config) do
    [{ 'id' => 'gemini', 'command' => 'gemini', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:config) { Jekyll::Drops::Validations::Gemini.new(id: 'gemini', yaml: yaml) }
  let(:template) { '{% include how-tos/validations/gemini/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered, lang: 'sh') }

  shared_examples 'a valid shell command' do
    it 'renders syntactically valid shell' do
      validate_bash_syntax!(code)
    end
  end

  context 'with base_url' do
    let(:yaml) do
      { 'model' => 'my-gemini-model', 'base_url' => 'http://localhost:8000/gemini', 'prompt' => "Tell me about the prisoner's dilemma." }
    end

    include_examples 'a valid shell command'

    it 'renders the GOOGLE_GEMINI_BASE_URL export before the base command' do
      expect(rendered).to eq(<<~MD)
        ```sh
        export GOOGLE_GEMINI_BASE_URL=http://localhost:8000/gemini

        gemini --model "my-gemini-model"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Tell me about the prisoner's dilemma.
        ```
      MD
    end
  end

  context 'with no base_url (synthetic)' do
    let(:yaml) { { 'model' => 'my-gemini-model', 'prompt' => 'Hello' } }

    include_examples 'a valid shell command'

    it 'renders the base command with no env export and no leading blank line' do
      expect(rendered).to eq(<<~MD)
        ```sh
        gemini --model "my-gemini-model"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Hello
        ```
      MD
    end
  end
end
