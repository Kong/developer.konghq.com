# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::RequestCheck do
  let(:url_origin) do
    { 'konnect' => 'https://konnect.example.com', 'on_prem' => 'http://localhost:8000' }
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'url_origin' => url_origin, 'validations' => [] } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'request-check', yaml:) }

  let(:yaml) { { 'url' => '/mock/anything', 'method' => 'GET' } }

  describe '#validate_yaml!' do
    context 'when url is missing' do
      let(:yaml) { { 'method' => 'GET' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `url` in {% validation request-check %}.') }
    end
  end

  describe '#konnect_snippet_config' do
    it 'resolves the url against the konnect origin' do
      expect(drop.konnect_snippet_config['url']).to eq('https://konnect.example.com/mock/anything')
    end

    it 'carries every snippet key' do
      expect(drop.konnect_snippet_config.keys)
        .to eq(Jekyll::Drops::Concerns::RequestSnippetConfig::SNIPPET_KEYS)
    end

    it 'reads the writer options from the block yaml' do
      expect(drop.konnect_snippet_config['method']).to eq('GET')
    end
  end

  describe '#on_prem_snippet_config' do
    it 'resolves the url against the on-prem origin' do
      expect(drop.on_prem_snippet_config['url']).to eq('http://localhost:8000/mock/anything')
    end

    it 'differs from the konnect config in the url only' do
      expect(drop.on_prem_snippet_config.except('url')).to eq(drop.konnect_snippet_config.except('url'))
    end
  end

  context 'when the block overrides an origin' do
    let(:yaml) { { 'url' => '/mock/anything', 'konnect_url' => 'https://other.example.com' } }

    it 'uses the override' do
      expect(drop.konnect_snippet_config['url']).to eq('https://other.example.com/mock/anything')
    end
  end

  context 'when the block sets an option that is not a snippet key' do
    let(:yaml) { { 'url' => '/mock/anything', 'status_code' => 200 } }

    it 'keeps it out of the snippet config' do
      expect(drop.konnect_snippet_config).not_to have_key('status_code')
    end
  end
end
