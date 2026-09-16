# frozen_string_literal: true

RSpec.describe Jekyll::Drops::HttpRequest do
  subject(:drop) { described_class.new(yaml:, format: 'html') }

  let(:yaml) { { 'url' => 'localhost:8000/anything', 'method' => 'GET', 'insecure' => true } }

  describe '#validate_yaml!' do
    context 'when url is missing' do
      let(:yaml) { { 'method' => 'GET' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `url` in {% http_request %}.') }
    end
  end

  describe '#snippet_config' do
    it 'keeps the url the writer set' do
      expect(drop.snippet_config['url']).to eq('localhost:8000/anything')
    end

    it 'carries every snippet key' do
      expect(drop.snippet_config.keys)
        .to eq(Jekyll::Drops::Concerns::RequestSnippetConfig::SNIPPET_KEYS)
    end

    it 'reads the writer options from the block yaml' do
      expect(drop.snippet_config['insecure']).to be(true)
    end

    context 'when the block sets an option that the template dropped before' do
      let(:yaml) { { 'url' => 'localhost:8000/anything', 'count' => 3 } }

      it 'passes it through' do
        expect(drop.snippet_config['count']).to eq(3)
      end
    end
  end

  it 'exposes no per-topology accessor' do
    expect(drop).not_to respond_to(:konnect_snippet_config)
  end
end
