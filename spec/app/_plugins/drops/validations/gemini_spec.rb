# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::Gemini do
  let(:configured_command) { 'gemini' }
  let(:validations_config) do
    [{ 'id' => 'gemini', 'command' => configured_command, 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:yaml) { { 'model' => 'my-gemini-model', 'prompt' => 'Explain this error message.' } }
  let(:base_command) { 'gemini --model "my-gemini-model"' }
  let(:full_command) { "#{base_command} --prompt \"Explain this error message.\" --skip-trust" }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'gemini', yaml:) }

  describe '#validate_yaml!' do
    context 'when model and prompt are present' do
      it { expect { drop }.not_to raise_error }
    end

    context 'when prompt is missing' do
      let(:yaml) { { 'model' => 'my-gemini-model' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `prompt` in {% validation gemini %}.') }
    end

    context 'when model is missing' do
      let(:yaml) { { 'prompt' => 'Explain this error message.' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `model` in {% validation gemini %}.') }
    end
  end

  it 'builds the base command from the configured command and quoted model' do
    expect(drop.base_command).to eq(base_command)
  end

  it 'builds the command from the base command plus quoted prompt flag' do
    expect(drop.command).to eq(full_command)
  end

  context 'when base_url is present' do
    let(:yaml) do
      {
        'model' => 'my-gemini-model',
        'prompt' => 'Explain this error message.',
        'base_url' => 'http://localhost:8000/gemini'
      }
    end
    let(:full_command) do
      'GOOGLE_GEMINI_BASE_URL=http://localhost:8000/gemini ' \
        "#{base_command} --prompt \"Explain this error message.\" --skip-trust"
    end

    it 'prefixes the command with GOOGLE_GEMINI_BASE_URL' do
      expect(drop.command).to eq(full_command)
    end
  end

  it 'serializes the id and merged config in #data_validate' do
    expected = {
      'name' => 'gemini',
      'config' => {
        'command' => full_command,
        'base_command' => drop.base_command,
        'expected' => { 'return_code' => 0 }
      }
    }
    expect(JSON.parse(drop.data_validate)).to eq(expected)
  end
end
