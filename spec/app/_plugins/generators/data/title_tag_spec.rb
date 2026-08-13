# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Data::TitleTag do
  let(:site_title) { 'Kong Docs' }
  let(:sitemap_exclusions) { [] }
  let(:site) do
    instance_double(Jekyll::Site,
                    config: { 'title' => site_title, 'sitemap' => { 'exclude' => sitemap_exclusions } })
  end
  let(:page_data) { { 'title' => 'My Page' } }
  let(:page_url) { '/some/page/' }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }

  subject { described_class.new(site:, page:) }

  describe '#process' do
    context 'when URL starts with /assets/mesh/somethin.yml - some .yml files in assets are treated as pages by jekyll we need to skip them' do
      let(:page_url) { '/assets/some-asset/' }
      it { expect(subject.process).to be_nil }
    end

    context 'when layout is none - some pages have layout set to none and should be skipped' do
      let(:page_data) { { 'title' => 'My Page', 'layout' => 'none' } }
      it { expect(subject.process).to be_nil }
    end

    context 'when URL is in sitemap exclusions' do
      let(:sitemap_exclusions) { [page_url] }
      it { expect(subject.process).to be_nil }
    end

    context 'when the page is the root URL' do
      let(:page_url) { '/' }

      before { subject.process }

      it 'sets title_tag to the site title' do
        expect(page.data['title_tag']).to eq(site_title)
      end

      it 'sets llm_title to the site title' do
        expect(page.data['llm_title']).to eq(site_title)
      end
    end

    context 'when the page is processable' do
      let(:title_double) do
        double('Title', title_sections: ['Section A', 'Section B'], llm_title: 'Section A SECTION B llm title')
      end

      before do
        allow(Jekyll::Data::Title::Base).to receive(:make_for).and_return(title_double)
        subject.process
      end

      it 'joins title_sections with " - " and appends site title' do
        expect(page.data['title_tag']).to eq("Section A - Section B | #{site_title}")
      end

      it 'sets llm_title from title object' do
        expect(page.data['llm_title']).to eq('Section A SECTION B llm title')
      end

      context 'when title_sections has duplicates' do
        let(:title_double) { double('Title', title_sections: %w[Same Same], llm_title: 'Same') }

        it 'deduplicates before joining' do
          expect(page.data['title_tag']).to eq("Same | #{site_title}")
        end
      end

      context 'when title_sections contains nil entries' do
        let(:title_double) { double('Title', title_sections: ['Section A', nil], llm_title: 'Section A') }

        it 'compacts nils before joining' do
          expect(page.data['title_tag']).to eq("Section A | #{site_title}")
        end
      end
    end
  end
end
