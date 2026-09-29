# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::Codex do
  let(:configured_command) { 'codex' }
  let(:validations_config) do
    [{ 'id' => 'codex', 'command' => configured_command, 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:yaml) do
    {
      'model' => 'gpt-5.4',
      'prompt' => 'Explain this error message.',
      'model_provider' => 'kong-ai-gateway',
      'model_provider_name' => 'Kong AI Gateway',
      'model_provider_base_url' => 'http://localhost:9000/codex',
      'model_provider_env_key' => 'OPENAI_API_KEY',
      'model_provider_wire_api' => 'chat'
    }
  end
  let(:flags) do
    [
      'model="gpt-5.4"',
      'model_provider="kong-ai-gateway"',
      'model_providers.kong-ai-gateway.name="Kong AI Gateway"',
      'model_providers.kong-ai-gateway.base_url="http://localhost:9000/codex"',
      'model_providers.kong-ai-gateway.env_key="OPENAI_API_KEY"',
      'model_providers.kong-ai-gateway.wire_api="chat"'
    ]
  end
  let(:expected_base_command) { configured_command }
  let(:full_command) do
    [
      configured_command, 'exec "Explain this error message."', *flags.map { |flag| "-c #{flag}" },
      '--skip-git-repo-check'
    ].join(' ')
  end

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'codex', yaml:) }

  describe '#validate_yaml!' do
    context 'when all required fields are present' do
      it { expect { drop }.not_to raise_error }
    end

    described_class::REQUIRED_FIELDS.each do |field|
      context "when #{field} is missing" do
        let(:yaml) { super().except(field) }

        it { expect { drop }.to raise_error(ArgumentError, "Missing `#{field}` in {% validation codex %}.") }
      end
    end
  end

  it 'builds the base command from the configured command alone' do
    expect(drop.base_command).to eq(expected_base_command)
  end

  it 'builds the command from the configured command, exec, -c config flags, and skip flag' do
    expect(drop.command).to eq(full_command)
  end

  it 'exposes the raw, unprefixed config flags' do
    expect(drop.flags).to eq(flags)
  end

  it 'serializes the id and merged config in #data_validate' do
    expected = {
      'name' => 'codex',
      'config' => {
        'command' => full_command,
        'base_command' => expected_base_command,
        'flags' => flags,
        'expected' => { 'return_code' => 0 }
      }
    }
    expect(JSON.parse(drop.data_validate)).to eq(expected)
  end
end
