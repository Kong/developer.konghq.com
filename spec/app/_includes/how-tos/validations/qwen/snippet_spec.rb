# frozen_string_literal: true

RSpec.describe 'how-tos/validations/qwen/snippet.md' do
  let(:validations_config) do
    [{ 'id' => 'qwen', 'command' => 'qwen', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:config) { Jekyll::Drops::Validations::Qwen.new(id: 'qwen', yaml: yaml) }
  let(:template) { '{% include how-tos/validations/qwen/snippet.md config=config %}' }

  subject(:rendered) { render_liquid(template, locals: { 'config' => config }) }
  let(:code) { bash_code_block(rendered, lang: 'sh') }
  let(:yaml) { { 'model' => 'my-qwen-dashscope', 'auth-type' => 'openai', 'prompt' => 'Explain the singleton pattern in Python.' } }

  it 'renders syntactically valid shell' do
    validate_bash_syntax!(code)
  end

  it 'renders the base command followed by the prompt' do
    expect(rendered).to eq(<<~'MD'.chomp)
      ```sh
      qwen --model "my-qwen-dashscope" --auth-type "openai"
      ```

      And ask a question to confirm that requests reach AI Gateway.

      ```text
      Explain the singleton pattern in Python.
      ```
    MD
  end
end
