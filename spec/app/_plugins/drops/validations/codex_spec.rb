# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::Codex do
  let(:configured_command) { 'codex' }
  let(:validations_config) do
    [{ 'id' => 'codex', 'command' => 'codex', 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:yaml) { { 'model' => 'gpt-5.4', 'prompt' => 'Explain this error message.' } }
  let(:base_command) { 'codex --model "gpt-5.4"' }
  let(:full_command) do
    'codex exec "Explain this error message." --model "gpt-5.4" --skip-git-repo-check'
  end

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'codex', yaml:) }

  describe '#validate_yaml!' do
    context 'when model and prompt are present' do
      it { expect { drop }.not_to raise_error }
    end

    context 'when prompt is missing' do
      let(:yaml) { { 'model' => 'gpt-5.4' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `prompt` in {% validation codex %}.') }
    end

    context 'when model is missing' do
      let(:yaml) { { 'prompt' => 'Explain this error message.' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `model` in {% validation codex %}.') }
    end
  end

  it 'builds the base command from the configured command, exec, and quoted model' do
    expect(drop.base_command).to eq(base_command)
  end

  it 'builds the command from the base command plus quoted prompt and skip flag' do
    expect(drop.command).to eq(full_command)
  end

  context 'when base_url is present' do
    let(:yaml) do
      {
        'model' => 'gpt-5.4',
        'prompt' => 'Explain this error message.',
        'base_url' => 'http://localhost:9000/codex'
      }
    end
    let(:full_command) do
      'OPENAI_BASE_URL=http://localhost:9000/codex codex exec "Explain this error message." --model "gpt-5.4" --skip-git-repo-check'
    end

    it 'prefixes the command with OPENAI_BASE_URL' do
      expect(drop.command).to eq(full_command)
    end
  end

  it 'serializes the id and merged config in #data_validate' do
    expected = {
      'name' => 'codex',
      'config' => {
        'command' => full_command,
        'base_command' => drop.base_command,
        'expected' => { 'return_code' => 0 }
      }
    }
    expect(JSON.parse(drop.data_validate)).to eq(expected)
  end
end
