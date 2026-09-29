# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::Qwen do
  let(:base_command) { 'qwen' }
  let(:validations_config) do
    [{ 'id' => 'qwen', 'command' => base_command, 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:yaml) do
    {
      'model' => 'my-model',
      'prompt' => 'Explain this error message.',
      'auth-type' => 'api-key'
    }
  end
  let(:command) do
    'qwen --model "my-model" --auth-type "api-key" --prompt "Explain this error message."'
  end
  let(:full_command) { command }
  let(:expected_base_command) { 'qwen --model "my-model" --auth-type "api-key"' }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'qwen', yaml:) }

  describe '#validate_yaml!' do
    context 'when model, prompt, auth-type are present' do
      it { expect { drop }.not_to raise_error }
    end

    context 'when prompt is missing' do
      let(:yaml) { { 'model' => 'my-model', 'auth-type' => 'api-key' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `prompt` in {% validation qwen %}.') }
    end

    context 'when model is missing' do
      let(:yaml) do
        {
          'prompt' => 'Explain this error message.',
          'auth-type' => 'api-key'
        }
      end

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `model` in {% validation qwen %}.') }
    end

    context 'when auth-type is missing' do
      let(:yaml) do
        { 'model' => 'my-model', 'prompt' => 'Explain this error message.' }
      end

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `auth-type` in {% validation qwen %}.') }
    end
  end

  it 'builds the base command with the quoted model and auth-type' do
    expect(drop.base_command).to eq(expected_base_command)
  end

  it 'builds the command with the quoted model, auth-type, and prompt' do
    expect(drop.command).to eq(command)
  end

  it 'serializes the id and merged config in #data_validate' do
    expected = {
      'name' => 'qwen',
      'config' => {
        'command' => full_command,
        'base_command' => expected_base_command,
        'expected' => { 'return_code' => 0 }
      }
    }
    expect(JSON.parse(drop.data_validate)).to eq(expected)
  end
end
