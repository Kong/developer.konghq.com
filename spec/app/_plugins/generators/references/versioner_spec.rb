# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::ReferencePages::Versioner do
  subject(:versioner) { described_class.new(site:, page:) }

  let(:gateway_product) do
    YAML.load_file(File.expand_path('../../../../fixtures/app/_data/products/gateway.yml', __dir__))
  end

  let(:site_data) { { 'products' => { 'gateway' => gateway_product } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:page) { instance_double(Jekyll::Page, url: page_url, data: page_data) }
  let(:page_url) { '/gateway/some-reference-page/' }
  let(:page_data) { { 'products' => ['gateway'] } }

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
  end

  describe '#process' do
    it 'runs the four phases and assigns base_url, release info, and canonical metadata' do
      allow(Jekyll::ReferencePages::Page::Base).to receive(:make_for).and_return(
        instance_double(Jekyll::ReferencePages::Page::Base, to_jekyll_page: :jekyll_page)
      )

      versioner.process

      expect(page.data['base_url']).to eq('/gateway/some-reference-page/')
      expect(page.data['canonical_url']).to eq('/gateway/some-reference-page/')
      expect(page.data['canonical?']).to be(true)
      expect(page.data['release'].number).to eq('3.10')
    end
  end

  describe '#set_base_url!' do
    it 'sets base_url on page data to the page url' do
      versioner.set_base_url!
      expect(page.data['base_url']).to eq('/gateway/some-reference-page/')
    end
  end

  describe '#set_release_info!' do
    context 'when the page is versioned but no release is in range' do
      let(:page_data) { { 'versioned' => true, 'products' => ['unknown'] } }

      it 'raises ArgumentError naming the page url' do
        expect { versioner.set_release_info! }
          .to raise_error(ArgumentError, /Missing release for page: #{page_url}/)
      end
    end

    context 'when a release is in range' do
      it 'merges the latest release, all releases, and a ReleasesDropdown into page.data' do
        versioner.set_release_info!

        expect(page.data['release'].number).to eq('3.10')
        expect(page.data['releases'].map(&:number)).to eq(['3.10', '3.9'])
        expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
      end
    end

    context 'when the page is versioned and a release is in range' do
      let(:page_data) { { 'versioned' => true, 'products' => ['gateway'] } }

      it 'does not raise and merges release info' do
        expect { versioner.set_release_info! }.not_to raise_error
        expect(page.data['release'].number).to eq('3.10')
      end
    end
  end

  describe '#handle_canonicals!' do
    context 'when the page is versioned' do
      let(:page_data) { { 'versioned' => true, 'products' => ['gateway'] } }

      it 'sets canonical_url to the page url and marks canonical? true - the page.url is the canonical, we generate versioned pages for each release later' do
        versioner.handle_canonicals!
        expect(page.data['canonical_url']).to eq('/gateway/some-reference-page/')
        expect(page.data['canonical?']).to be(true)
      end
    end

    context 'when min_release is greater than latest_available_release' do
      let(:page_data) do
        { 'products' => ['gateway'], 'min_version' => { 'gateway' => '3.11' } }
      end

      context 'and the page is a plugin changelog' do
        let(:page_data) do
          { 'products' => ['gateway'], 'min_version' => { 'gateway' => '3.11' }, 'plugin?' => true,
            'changelog?' => true }
        end

        it 'does not unpublish the page' do
          versioner.handle_canonicals!
          expect(page.data).not_to include('published')
        end
      end
    end

    context 'when max_release is less than latest_available_release' do
      let(:page_data) do
        { 'products' => ['gateway'], 'max_version' => { 'gateway' => '3.9' } }
      end

      it 'unpublishes the page and points canonical at the max-release archive' do
        versioner.handle_canonicals!
        expect(page.data).to include(
          'published' => false,
          'canonical_url' => '/gateway/some-reference-page/3.9/'
        )
      end
    end

    context 'when no min or max constraint applies' do
      it 'marks the page as its own canonical' do
        versioner.handle_canonicals!
        expect(page.data['canonical_url']).to eq('/gateway/some-reference-page/')
        expect(page.data['canonical?']).to be(true)
      end
    end
  end

  describe '#generate_pages!' do
    let(:made_page) { instance_double(Jekyll::ReferencePages::Page::Base, to_jekyll_page: :jekyll_page) }

    context 'when the page is a plugin changelog' do
      let(:page_url) { '/plugins/acme/changelog/' }
      let(:page_data) { { 'products' => ['gateway'], 'plugin?' => true, 'changelog?' => true } }

      it 'returns an empty array' do
        expect(versioner.generate_pages!).to eq([])
      end
    end

    context 'when the page is not versioned and is in range' do
      it 'returns an empty array' do
        expect(versioner.generate_pages!).to eq([])
      end
    end

    context 'when the page is versioned' do
      let(:page_data) { { 'products' => ['gateway'], 'versioned' => true } }

      before do
        allow(page).to receive(:dir).and_return('/gateway/some-reference-page/')
        allow(page).to receive(:content).and_return('')
        allow(page).to receive(:relative_path).and_return('_gateway/index.md')
      end

      it 'generates one Jekyll page per release with correct url, seo_noindex, and canonical?' do
        pages = versioner.generate_pages!

        expect(pages.size).to eq(2)

        expect(pages[0].url).to eq('/gateway/some-reference-page/3.10/')
        expect(pages[0].data['seo_noindex']).to be(true)
        expect(pages[0].data['canonical?']).to be(false)

        expect(pages[1].url).to eq('/gateway/some-reference-page/3.9/')
        expect(pages[1].data['seo_noindex']).to be(true)
        expect(pages[1].data['canonical?']).to be(false)
      end
    end

    context 'in production with no min-release in the future' do
      around do |example|
        original = ENV.fetch('JEKYLL_ENV', nil)
        ENV['JEKYLL_ENV'] = 'production'
        example.run
      ensure
        ENV['JEKYLL_ENV'] = original
      end

      it 'skips generation for non-versioned pages' do
        expect(Jekyll::ReferencePages::Page::Base).not_to receive(:make_for)
        expect(versioner.generate_pages!).to eq([])
      end
    end
  end

  describe 'release_info delegation' do
    it 'delegates the public release-info methods to the underlying ReleaseInfo object' do
      expect(versioner.latest_release_in_range.number).to eq('3.10')
      expect(versioner.latest_available_release.number).to eq('3.10')
      expect(versioner.releases.map(&:number)).to eq(['3.10', '3.9'])
      expect(versioner.deduplicated_releases.map(&:number)).to eq(['3.10', '3.9'])
      expect(versioner.use_release_name?).to eq(false)
      expect(versioner.min_release).to be_nil
      expect(versioner.max_release).to be_nil
    end
  end
end
