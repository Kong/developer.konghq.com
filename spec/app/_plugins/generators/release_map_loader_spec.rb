# frozen_string_literal: true

require_relative '../../../../app/_plugins/generators/release_map_loader'

RSpec.describe Jekyll::ReleaseMapLoader do
  subject(:generator) { described_class.new }

  let(:data) do
    { 'products' => { 'ai-gateway' => { 'name' => 'AI Gateway',
                                        'previous_major_url_segment' => 'v<major>',

                                        'releases' => [{ 'release' => '2.0', 'latest' => true },
                                                       { 'release' => '1.0' }] } } }
  end
  let(:site) { instance_double(Jekyll::Site, pages: pages, documents: documents, data:, config: {}) }
  let(:pages) { [] }
  let(:documents) { [] }

  let(:prev_major_page) do
    instance_double(Jekyll::Page,
                    data: { 'major_version' => { 'ai-gateway' => 1 } },
                    url: '/ai-gateway/v1/valid-page/',
                    relative_path: '_how-tos/ai-gateway/v1/valid-page.md')
  end

  let(:current_major_page) do
    instance_double(Jekyll::Page,
                    data: {},
                    url: '/ai-gateway/valid-page/',
                    relative_path: '_how-tos/ai-gateway/valid-page.md')
  end

  before do
    allow(ReleaseMap).to receive(:load_all).with(site).and_return(release_map)
  end

  let(:release_map) { {} }

  shared_examples 'sets the banner info for a page' do
    it 'attaches cross_major_banner_info to the page' do
      generator.generate(site)
      expect(prev_major_page.data['cross_major_banner_info']).to eq(
        'product' => 'AI Gateway',
        'major_version' => 'v1'
      )
    end
  end

  describe '#generate' do
    context 'with a release-map entry pointing at a live current-major page' do
      let(:pages) { [prev_major_page, current_major_page] }
      let(:release_map) do
        { 'app/_how-tos/ai-gateway/v1/valid-page.md' => { 'canonical_url' => '/ai-gateway/valid-page/' } }
      end

      it 'attaches canonical_url to the page' do
        generator.generate(site)
        expect(prev_major_page.data['canonical_url']).to eq('/ai-gateway/valid-page/')
      end

      it_behaves_like 'sets the banner info for a page'

      it 'sets previous major urls to the canonical page' do
        generator.generate(site)

        expect(current_major_page.data['previous_major_urls'])
          .to eq({ 'v1' => '/ai-gateway/v1/valid-page/' })
      end
    end

    context 'with a status: pending entry' do
      let(:pages) { [prev_major_page] }
      let(:release_map) do
        { 'app/_how-tos/ai-gateway/v1/valid-page.md' => { 'status' => 'pending', 'canonical_url' => nil } }
      end

      it 'skips validation and does not attach canonical_url' do
        generator.generate(site)
        expect(prev_major_page.data['canonical_url']).to be_nil
      end

      it_behaves_like 'sets the banner info for a page'
    end

    context 'with a status other than pending entry' do
      let(:pages) { [prev_major_page] }
      let(:release_map) do
        { 'app/_how-tos/ai-gateway/v1/valid-page.md' => { 'status' => 'invalid', 'canonical_url' => nil } }
      end

      it 'raises' do
        expect do
          generator.generate(site)
        end.to raise_error(%r{invalid status: invalid for app/_how-tos/ai-gateway/v1/valid-page.md})
      end
    end

    context 'with a blank canonical_url and no pending flag' do
      let(:pages) { [prev_major_page] }
      let(:release_map) do
        { 'app/_how-tos/ai-gateway/v1/valid-page.md' => { 'canonical_url' => nil } }
      end

      it 'raises' do
        expect do
          generator.generate(site)
        end.to raise_error(/blank canonical_url for non-pending entry/)
      end
    end

    context 'with a canonical_url equal to the page url (self-canonical)' do
      let(:pages) { [prev_major_page] }
      let(:release_map) do
        { 'app/_how-tos/ai-gateway/v1/valid-page.md' => { 'canonical_url' => '/ai-gateway/v1/valid-page/' } }
      end

      it 'is valid and attaches canonical_url' do
        generator.generate(site)
        expect(prev_major_page.data['canonical_url']).to eq('/ai-gateway/v1/valid-page/')
      end

      it_behaves_like 'sets the banner info for a page'
    end
  end
end
