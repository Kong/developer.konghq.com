# frozen_string_literal: true

RSpec.describe Jekyll::Drops::ControlPlaneRequest do
  let(:url_origin) do
    { 'konnect' => '$KONNECT_CONTROL_PLANE_URL', 'on_prem' => 'http://localhost:8001' }
  end
  let(:site_data) { { 'control_plane_request' => { 'url_origin' => url_origin } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(yaml:, format: 'html') }

  let(:yaml) { { 'url' => '/services', 'method' => 'POST', 'display_headers' => true } }

  describe '#validate_yaml!' do
    context 'when url is missing' do
      let(:yaml) { { 'method' => 'POST' } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `url` in {% control_plane_request %}.') }
    end
  end

  describe '#validate_section!' do
    context 'when section is unrecognized' do
      let(:yaml) { { 'url' => '/services', 'section' => 'prereq' } }

      it 'raises an error naming the rejected value' do
        expect { drop }.to raise_error(ArgumentError, /prereq/)
      end
    end
  end

  describe '#config' do
    let(:yaml) { { 'url' => '/services', 'section' => 'cleanup' } }

    it 'drops section from the instruction config' do
      expect(drop.config).not_to have_key('section')
    end
  end

  describe '#konnect_snippet_config' do
    it 'resolves the url against the konnect origin' do
      expect(drop.konnect_snippet_config['url']).to eq('$KONNECT_CONTROL_PLANE_URL/services')
    end

    it 'carries every snippet key' do
      expect(drop.konnect_snippet_config.keys)
        .to eq(Jekyll::Drops::Concerns::RequestSnippetConfig::SNIPPET_KEYS)
    end

    it 'carries an option that the template dropped before' do
      expect(drop.konnect_snippet_config['display_headers']).to be(true)
    end
  end

  describe '#on_prem_snippet_config' do
    it 'resolves the url against the on-prem origin' do
      expect(drop.on_prem_snippet_config['url']).to eq('http://localhost:8001/services')
    end

    it 'differs from the konnect config in the url only' do
      expect(drop.on_prem_snippet_config.except('url')).to eq(drop.konnect_snippet_config.except('url'))
    end
  end

  context 'when the block sets a capture' do
    let(:yaml) do
      { 'url' => '/services', 'capture' => [{ 'variable' => 'SERVICE_ID', 'jq' => '.id' }] }
    end

    it 'passes the capture through' do
      expect(drop.konnect_snippet_config['capture'])
        .to eq([{ 'variable' => 'SERVICE_ID', 'jq' => '.id' }])
    end
  end

  context 'when the block sets a key that is not a snippet option' do
    let(:yaml) { { 'url' => '/services', 'status_code' => 201 } }

    it 'keeps it out of the snippet config' do
      expect(drop.konnect_snippet_config).not_to have_key('status_code')
    end
  end
end
