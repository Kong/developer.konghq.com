# frozen_string_literal: true

require_relative '../../../../../app/_plugins/generators/data/seo'

RSpec.describe Jekyll::Data::Seo do
  let(:page_data) { {} }
  let(:page_url) { '/some/page/' }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }
  let(:sitemap_exclusions) { [] }
  let(:site) { instance_double(Jekyll::Site, config: { 'sitemap' => { 'exclude' => sitemap_exclusions } }) }

  describe '#process' do
    subject! { described_class.new(site:, page:).process }

    context 'when canonical? is already set on the page' do
      let(:page_data) { { 'canonical?' => true } }

      it 'returns early without modifying page data further' do
        expect(page.data).to eq({ 'canonical?' => true })
      end
    end

    context 'when the URL starts with /assets/mesh/' do
      let(:page_url) { '/assets/mesh/some-asset.js' }

      it 'returns early without modifying page data' do
        expect(page.data).to be_empty
      end
    end

    context 'when the page is canonical' do
      let(:page_data) { { 'content_type' => 'how_to' } }

      it 'sets canonical? to true and canonical_url to the page url' do
        expect(page.data['canonical?']).to be true
        expect(page.data['canonical_url']).to eq(page_url)
      end

      it 'does not set seo_noindex' do
        expect(page.data['seo_noindex']).to be_nil
      end
    end

    context 'when the page is not canonical' do
      let(:page_data) { {} }
      let(:sitemap_exclusions) { [page_url] }

      it 'sets seo_noindex to true and canonical? to false' do
        expect(page.data['seo_noindex']).to be true
        expect(page.data['canonical?']).to be false
      end

      it 'does not set canonical_url' do
        expect(page.data['canonical_url']).to be_nil
      end

      context 'when the page is from an old major release regardless of the content_type' do
        let(:page_url) { '/ai-gateway/v1/valid-page/' }

        %w[how_to landing_page concept plugin reference api].each do |content_type|
          let(:page_data) { { 'major_version' => { 'ai-gateway' => 1 }, 'content_type' => content_type } }

          it 'sets seo_noindex to true and canonical? to false' do
            expect(page.data['seo_noindex']).to be true
            expect(page.data['canonical?']).to be false
          end
        end
      end
    end
  end

  describe '#canonical?' do
    subject { described_class.new(site:, page:).canonical? }

    context 'with content_type how_to' do
      let(:page_data) { { 'content_type' => 'how_to' } }

      it { expect(subject).to be true }
    end

    context 'when the page is from an old major release' do
      let(:page_data) { { 'major_version' => { 'ai-gateway' => 1 } } }
      let(:page_url) { '/ai-gateway/v1/valid-page/' }

      it { expect(subject).to be false }
    end

    context 'when the page is not from an old major release' do
      context 'with content_type landing_page' do
        let(:page_data) { { 'content_type' => 'landing_page' } }

        it { expect(subject).to be true }
      end

      context 'with content_type concept' do
        let(:page_data) { { 'content_type' => 'concept' } }

        it { expect(subject).to be true }
      end

      context 'with content_type plugin' do
        let(:page_data) { { 'content_type' => 'plugin' } }

        it { expect(subject).to be true }
      end

      context 'with content_type reference' do
        context 'when canonical? is true on the page' do
          let(:page_data) { { 'content_type' => 'reference', 'canonical?' => true } }

          it { expect(subject).to be true }
        end

        context 'when canonical? is false on the page' do
          let(:page_data) { { 'content_type' => 'reference', 'canonical?' => false } }

          it { expect(subject).to be false }
        end

        context 'when canonical? is absent on the page' do
          let(:page_data) { { 'content_type' => 'reference' } }

          it { expect(subject).to be_nil }
        end
      end

      context 'with content_type api' do
        context 'when canonical? is true on the page' do
          let(:page_data) { { 'content_type' => 'api', 'canonical?' => true } }

          it { expect(subject).to be true }
        end

        context 'when canonical? is false on the page' do
          let(:page_data) { { 'content_type' => 'api', 'canonical?' => false } }

          it { expect(subject).to be false }
        end
      end

      context 'with an unrecognised content_type' do
        let(:page_data) { { 'content_type' => 'other' } }

        context 'when the page url is not in sitemap exclusions' do
          let(:sitemap_exclusions) { ['/other/page/'] }

          it { expect(subject).to be true }
        end

        context 'when the page url is in sitemap exclusions' do
          let(:sitemap_exclusions) { [page_url] }

          it { expect(subject).to be false }
        end
      end

      context 'with no content_type set' do
        let(:page_data) { {} }

        context 'when the page url is not in sitemap exclusions' do
          it { expect(subject).to be true }
        end

        context 'when the page url is in sitemap exclusions' do
          let(:sitemap_exclusions) { [page_url] }

          it { expect(subject).to be false }
        end
      end
    end
  end
end
