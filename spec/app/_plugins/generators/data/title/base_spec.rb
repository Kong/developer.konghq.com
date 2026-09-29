# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::Data::Title::Base do
  let(:site) { instance_double(Jekyll::Site) }
  let(:page_data) { {} }
  let(:page) { instance_double(Jekyll::Page, url: page_url, data: page_data) }

  describe '.make_for' do
    subject { described_class.make_for(page:, site:) }

    context 'when URL starts with /api/' do
      let(:page_url) { '/api/some-api/' }
      it { expect(subject).to be_a(Jekyll::Data::Title::APIPage) }
    end

    context 'when URL starts with /plugins/' do
      let(:page_url) { '/plugins/rate-limiting/' }
      it { expect(subject).to be_a(Jekyll::Data::Title::Plugin) }
    end

    context 'when URL starts with /mesh/policies/' do
      let(:page_url) { '/mesh/policies/meshretry/' }
      it { expect(subject).to be_a(Jekyll::Data::Title::Policy) }
    end

    context 'when URL starts with /event-gateway/policies/' do
      let(:page_url) { '/event-gateway/policies/some-policy/' }
      it { expect(subject).to be_a(Jekyll::Data::Title::Policy) }
    end

    context 'when URL starts with /ai-gateway/policies/' do
      let(:page_url) { '/ai-gateway/policies/some-policy/' }
      it { expect(subject).to be_a(Jekyll::Data::Title::Policy) }
    end

    context 'when content_type is reference' do
      let(:page_url) { '/gateway/reference/cli/' }
      let(:page_data) { { 'content_type' => 'reference' } }
      it { expect(subject).to be_a(Jekyll::Data::Title::Reference) }
    end

    context 'when content_type is how_to' do
      let(:page_url) { '/how-tos/configure-rate-limiting/' }
      let(:page_data) { { 'content_type' => 'how_to' } }
      it { expect(subject).to be_a(Jekyll::Data::Title::HowTo) }
    end

    context 'when page has no special URL or content type' do
      let(:page_url) { '/gateway/some-page/' }
      let(:page_data) { { 'title' => 'Some Page' } }

      it 'returns title_sections with the page title' do
        expect(subject.title_sections).to eq(['Some Page'])
      end

      it 'returns llm_title as the page title' do
        expect(subject.llm_title).to eq('Some Page')
      end
    end
  end
end
