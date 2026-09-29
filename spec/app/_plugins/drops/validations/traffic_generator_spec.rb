# frozen_string_literal: true

RSpec.describe Jekyll::Drops::Validations::TrafficGenerator do
  let(:url_origin) do
    { 'konnect' => 'https://konnect.example.com', 'on_prem' => 'http://localhost:8000' }
  end
  let(:site_data) { { 'how-tos' => { 'config' => { 'url_origin' => url_origin, 'validations' => [] } } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  subject(:drop) { described_class.new(id: 'traffic-generator', yaml:) }

  let(:yaml) { { 'url' => '/mock/anything', 'iterations' => 5 } }

  describe '#validate_yaml!' do
    context 'when iterations is missing' do
      let(:yaml) { { 'url' => '/mock/anything' } }

      it do
        expect { drop }.to raise_error(
          ArgumentError, 'Missing `iterations` in {% validation traffic-generator %}.'
        )
      end
    end

    context 'when url is missing' do
      let(:yaml) { { 'iterations' => 5 } }

      it { expect { drop }.to raise_error(ArgumentError, 'Missing `url` in {% validation traffic-generator %}.') }
    end

    context 'when grep is set without output.expected' do
      let(:yaml) { { 'url' => '/mock/anything', 'iterations' => 5, 'grep' => 'hello' } }

      it { expect { drop }.not_to raise_error }
    end
  end

  describe '#snippet_config_overrides' do
    it 'maps iterations onto count' do
      expect(drop.konnect_snippet_config['count']).to eq(5)
    end
  end

  it 'keeps grep out of the snippet config' do
    expect(drop.konnect_snippet_config).not_to have_key('grep')
  end

  it 'resolves the url per topology' do
    expect(drop.on_prem_snippet_config['url']).to eq('http://localhost:8000/mock/anything')
  end
end
