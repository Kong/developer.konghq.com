# frozen_string_literal: true

RSpec.describe 'how-tos/validations/codex/snippet.md' do
  let(:validations_config) do
    [{ 'id' => 'codex', 'command' => 'codex', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:yaml) do
    {
      'model' => 'codex-openai',
      'model_provider' => 'my-gateway',
      'model_provider_name' => 'AI Quickstart',
      'model_provider_base_url' => 'http://localhost:8000/',
      'model_provider_env_key' => 'OPENAI_API_KEY',
      'model_provider_wire_api' => 'responses',
      'prompt' => 'Tell me about the Madrid Skylitzes manuscript.'
    }
  end
  let(:config) { Jekyll::Drops::Validations::Codex.new(id: 'codex', yaml: yaml) }
  let(:template) { '{% include how-tos/validations/codex/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered, lang: 'sh') }

  it 'renders syntactically valid shell' do
    validate_bash_syntax!(code)
  end

  it 'renders the base command with a --config flag per model provider setting' do
    expect(rendered).to eq(<<~MD)
      ```sh
      codex \\
        --config model="codex-openai" \\
        --config model_provider="my-gateway" \\
        --config model_providers.my-gateway.name="AI Quickstart" \\
        --config model_providers.my-gateway.base_url="http://localhost:8000/" \\
        --config model_providers.my-gateway.env_key="OPENAI_API_KEY" \\
        --config model_providers.my-gateway.wire_api="responses"
      ```

      And ask a question to confirm that requests reach AI Gateway.

      ```text
      Tell me about the Madrid Skylitzes manuscript.
      ```
    MD
  end
end
