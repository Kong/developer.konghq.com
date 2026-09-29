# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::ClaudeCode do
  let(:base_command) { 'ANTHROPIC_BASE_URL=http://localhost:8000/ claude' }
  let(:validations_config) do
    [{ 'id' => 'claude-code', 'command' => base_command, 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:yaml) { { 'model' => 'my-model', 'prompt' => 'Explain this error message.' } }
  let(:full_command) { "#{base_command} --model \"my-model\" -p \"Explain this error message.\"" }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'claude-code', yaml:) }

  describe '#validate_yaml!' do
    context 'when model and prompt are present' do
      it { expect { drop }.not_to raise_error }
    end

    context 'when prompt is missing' do
      let(:yaml) { { 'model' => 'my-model' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `prompt` in {% validation claude-code %}.') }
    end

    context 'when model is missing' do
      let(:yaml) { { 'prompt' => 'Explain this error message.' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `model` in {% validation claude-code %}.') }
    end
  end

  it 'builds the command from the configured base command plus quoted model and prompt' do
    expect(drop.command).to eq(full_command)
  end

  context 'when disable_experimental_betas is true and base_url is present' do
    let(:yaml) do
      {
        'model' => 'my-model',
        'prompt' => 'Explain this error message.',
        'disable_experimental_betas' => true,
        'base_url' => 'http://localhost:9000/'
      }
    end
    let(:full_command) do
      "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 ANTHROPIC_BASE_URL=http://localhost:9000/ " \
        "#{base_command} --model \"my-model\" -p \"Explain this error message.\""
    end

    it 'prefixes the command with both env variables' do
      expect(drop.command).to eq(full_command)
    end
  end

  context 'when only disable_experimental_betas is true' do
    let(:yaml) do
      { 'model' => 'my-model', 'prompt' => 'Explain this error message.', 'disable_experimental_betas' => true }
    end
    let(:full_command) do
      "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 #{base_command} --model \"my-model\" -p \"Explain this error message.\""
    end

    it 'prefixes the command with only that env variable' do
      expect(drop.command).to eq(full_command)
    end
  end

  context 'when only base_url is present' do
    let(:yaml) do
      {
        'model' => 'my-model',
        'prompt' => 'Explain this error message.',
        'base_url' => 'http://localhost:9000/'
      }
    end
    let(:full_command) do
      "ANTHROPIC_BASE_URL=http://localhost:9000/ #{base_command} --model \"my-model\" -p \"Explain this error message.\""
    end

    it 'prefixes the command with only that env variable' do
      expect(drop.command).to eq(full_command)
    end
  end

  it 'serializes the id and merged config in #data_validate' do
    expected = {
      'name' => 'claude-code',
      'config' => {
        'command' => full_command,
        'base_command' => drop.base_command,
        'expected' => { 'return_code' => 0 }
      }
    }
    expect(JSON.parse(drop.data_validate)).to eq(expected)
  end
end
