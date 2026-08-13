# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::Codex do
  let(:base_command) { 'OPENAI_BASE_URL=http://localhost:8000/codex codex' }
  let(:validations_config) do
    [{ 'id' => 'codex', 'command' => base_command, 'expected' => { 'return_code' => 0 } }]
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'validations' => validations_config } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:yaml) { { 'model' => 'gpt-5.4', 'prompt' => 'Explain this error message.' } }
  let(:full_command) do
    "#{base_command} exec --model \"gpt-5.4\" \"Explain this error message.\" --skip-git-repo-check"
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

  it 'builds the command from the configured base command plus exec, quoted model, prompt, and skip flag' do
    expect(drop.command).to eq(full_command)
  end

  it 'serializes the id and merged config in #data_validate' do
    expected = {
      'name' => 'codex',
      'config' => { 'command' => full_command, 'expected' => { 'return_code' => 0 } }
    }
    expect(JSON.parse(drop.data_validate)).to eq(expected)
  end
end
