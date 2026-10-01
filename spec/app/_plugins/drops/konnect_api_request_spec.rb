# frozen_string_literal: true

RSpec.describe Jekyll::Drops::KonnectApiRequest do
  let(:site_data) { { 'konnect_api_request' => { 'region' => 'us' } } }
  let(:site_config) { { 'konnect_domain' => 'konghq.com' } }
  let(:site) { instance_double(Jekyll::Site, data: site_data, config: site_config) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(yaml:, format: 'html') }

  let(:yaml) { { 'url' => '/v2/control-planes', 'method' => 'POST' } }

  describe '#validate_yaml!' do
    context 'when url is missing' do
      let(:yaml) { { 'method' => 'POST' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `url` in {% konnect_api_request %}.') }
    end
  end

  describe '#snippet_config' do
    it 'targets the region api host' do
      expect(drop.snippet_config['url']).to eq('https://us.api.konghq.com/v2/control-planes')
    end

    it 'carries the authorization header once' do
      expect(drop.snippet_config['headers']).to eq(['Authorization: Bearer $KONNECT_TOKEN'])
    end

    it 'carries every snippet key' do
      expect(drop.snippet_config.keys)
        .to eq(Jekyll::Drops::Concerns::RequestSnippetConfig::SNIPPET_KEYS)
    end

    context 'when the block sets its own region' do
      let(:yaml) { { 'url' => '/v2/control-planes', 'region' => 'eu' } }

      it 'targets that region' do
        expect(drop.snippet_config['url']).to eq('https://eu.api.konghq.com/v2/control-planes')
      end
    end

    context 'when the site configures a Konnect domain' do
      let(:site_config) { { 'konnect_domain' => 'konghq.tech' } }

      it 'targets that domain' do
        expect(drop.snippet_config['url']).to eq('https://us.api.konghq.tech/v2/control-planes')
      end
    end


    context 'when the writer also sets headers' do
      let(:yaml) do
        { 'url' => '/v2/control-planes', 'headers' => ['Content-Type: application/json'] }
      end

      it 'carries the writer headers and the authorization header once each' do
        expect(drop.snippet_config['headers'])
          .to eq(['Authorization: Bearer $KONNECT_TOKEN', 'Content-Type: application/json'])
      end
    end

    context 'when the block sets an option that the template dropped before' do
      let(:yaml) { { 'url' => '/v2/control-planes', 'expected_headers' => ['X-Kong-Admin: true'] } }

      it 'passes it through' do
        expect(drop.snippet_config['expected_headers']).to eq(['X-Kong-Admin: true'])
      end
    end
  end

  it 'exposes no on-prem accessor' do
    expect(drop).not_to respond_to(:on_prem_snippet_config)
  end
end
