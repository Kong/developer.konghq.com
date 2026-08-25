# frozen_string_literal: true

# Config fixtures below are adapted from real {% validation claude-code %} blocks in
# app/_how-tos/ai-gateway/use-claude-code-with-ai-gateway-*.md. Real docs only ever set
# `base_url` alone or `base_url` + `disable_experimental_betas` together, so the "disable
# only" and "neither" cases are synthetic, built directly from the snippet.md logic, to get
# full branch coverage of the env_exports capture.
RSpec.describe 'how-tos/validations/claude-code/snippet.md' do
  let(:validations_config) do
    [{ 'id' => 'claude-code', 'command' => 'claude', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:config) { Jekyll::Drops::Validations::ClaudeCode.new(id: 'claude-code', yaml: yaml) }
  let(:template) { '{% include how-tos/validations/claude-code/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered, lang: 'sh') }

  shared_examples 'a valid shell command' do
    it 'renders syntactically valid shell' do
      validate_bash_syntax!(code)
    end
  end

  context 'with base_url only (use-claude-code-with-ai-gateway-anthropic.md)' do
    let(:yaml) do
      {
        'model' => 'my-claude',
        'prompt' => 'Tell me about the Madrid Skylitzes manuscript.',
        'base_url' => 'http://localhost:8000/'
      }
    end

    include_examples 'a valid shell command'

    it 'renders the base_url export and the base command, with no disable_experimental_betas export' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```sh
        export ANTHROPIC_BASE_URL=http://localhost:8000/

        claude --model "my-claude"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Tell me about the Madrid Skylitzes manuscript.
        ```
      MD
    end
  end

  context 'with base_url and disable_experimental_betas (use-claude-code-with-ai-gateway-bedrock.md)' do
    let(:yaml) do
      {
        'model' => 'my-claude-bedrock',
        'prompt' => 'Tell me about the Madrid Skylitzes manuscript.',
        'base_url' => 'http://localhost:8000/',
        'disable_experimental_betas' => true
      }
    end

    include_examples 'a valid shell command'

    it 'renders both env exports before the base command' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```sh
        export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
        export ANTHROPIC_BASE_URL=http://localhost:8000/

        claude --model "my-claude-bedrock"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Tell me about the Madrid Skylitzes manuscript.
        ```
      MD
    end
  end

  context 'with disable_experimental_betas only, no base_url (synthetic)' do
    let(:yaml) do
      { 'model' => 'my-model', 'prompt' => 'Explain this error message.', 'disable_experimental_betas' => true }
    end

    include_examples 'a valid shell command'

    it 'renders only the disable_experimental_betas export' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```sh
        export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

        claude --model "my-model"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Explain this error message.
        ```
      MD
    end
  end

  context 'with neither base_url nor disable_experimental_betas (synthetic)' do
    let(:yaml) { { 'model' => 'my-model', 'prompt' => 'Explain this error message.' } }

    include_examples 'a valid shell command'

    it 'renders the base command with no env exports and no leading blank line' do
      expect(rendered).to eq(<<~'MD'.chomp)
        ```sh
        claude --model "my-model"
        ```

        And ask a question to confirm that requests reach AI Gateway.

        ```text
        Explain this error message.
        ```
      MD
    end
  end
end
