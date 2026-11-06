# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::ReferencePages::Generator do
  subject(:generator) { described_class.new(site) }

  let(:site) { JekyllSite.build }
  let(:page) { site.pages.find { |p| p.url == '/gateway/reference-page/' } }

  before { page.data['versioned'] = true }

  describe '#version_pages!' do
    context 'when the page sets skip_versioner' do
      let(:releases) do
        [
          Jekyll::Drops::Release.new({ 'release' => '3.10', 'latest' => true }),
          Jekyll::Drops::Release.new({ 'release' => '3.9' })
        ]
      end
      let(:releases_dropdown) do
        Jekyll::Drops::ReleasesDropdown.new(base_url: '/gateway/reference-page/', releases:)
      end

      before do
        page.data.merge!(
          'skip_versioner' => true,
          'releases_dropdown' => releases_dropdown,
          'canonical?' => true,
          'canonical_url' => '/gateway/reference-page/'
        )
      end

      it 'generates no per-release copies' do
        expect { generator.version_pages! }
          .not_to(change { site.pages.map(&:url).grep(%r{\A/gateway/reference-page/}) })
      end

      it 'keeps the releases_dropdown and canonical data the page was generated with' do
        generator.version_pages!

        expect(page.data['releases_dropdown']).to equal(releases_dropdown)
        expect(page.data['canonical?']).to be(true)
        expect(page.data['canonical_url']).to eq('/gateway/reference-page/')
      end

      it 'does not set release or base_url the versioner would have derived' do
        generator.version_pages!

        expect(page.data).not_to have_key('release')
        expect(page.data).not_to have_key('base_url')
      end
    end

    context 'when the page does not set skip_versioner' do
      it 'keeps the current behavior: versioner data and per-release copies' do
        generator.version_pages!

        expect(site.pages.map(&:url)).to include('/gateway/reference-page/3.9/')
        expect(page.data['releases_dropdown']).to be_a(Jekyll::Drops::ReleasesDropdown)
        expect(page.data['releases_dropdown'].options.map(&:url))
          .to match_array(['/gateway/reference-page/', '/gateway/reference-page/3.9/'])
        expect(page.data['release'].number).to eq('3.10')
        expect(page.data['canonical?']).to be(true)
      end
    end
  end

  describe '#version_docs!' do
    let(:doc_data) { { 'content_type' => 'reference', 'skip_versioner' => true } }
    let(:doc) { instance_double(Jekyll::Document, data: doc_data) }

    before { allow(site).to receive(:documents).and_return([doc]) }

    context 'when the document sets skip_versioner' do
      it 'generates no per-release copies' do
        expect(Jekyll::ReferencePages::Versioner).not_to receive(:new)

        expect { generator.version_docs! }.not_to(change { site.pages.map(&:url) })
      end
    end

    context 'when the document does not set skip_versioner' do
      let(:doc_data) { { 'content_type' => 'reference' } }

      it 'still runs the versioner for the document' do
        versioner = instance_double(Jekyll::ReferencePages::Versioner, process: [])
        expect(Jekyll::ReferencePages::Versioner).to receive(:new).with(site:, page: doc).and_return(versioner)

        generator.version_docs!
      end
    end
  end
end
