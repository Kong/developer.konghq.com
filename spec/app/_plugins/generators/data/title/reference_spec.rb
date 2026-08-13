# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::Data::Title::Reference do
  let(:site) { instance_double(Jekyll::Site, data: site_data) }
  let(:site_data) do
    { 'products' => { 'gateway' => { 'name' => 'Kong Gateway' } }, 'tools' => { 'deck' => { 'name' => 'decK' } } }
  end
  let(:page_data) { { 'title' => 'Install Kong Gateway', 'products' => ['gateway'], 'canonical?' => true } }
  let(:page_url) { '/gateway/install/' }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }

  subject { described_class.new(page:, site:) }

  describe '#title_sections' do
    it 'returns page title, version, and product or tool' do
      expect(subject.title_sections).to eq(['Install Kong Gateway', nil, 'Kong Gateway'])
    end

    context 'when version is present' do
      let(:page_url) { '/gateway/install/3.9/' }
      let(:page_data) do
        { 'title' => 'Install Kong Gateway', 'products' => ['gateway'], 'release' => '3.9', 'canonical?' => false }
      end
      it { expect(subject.title_sections).to eq(['Install Kong Gateway', 'v3.9', 'Kong Gateway']) }
    end
  end

  describe '#llm_title' do
    it { expect(subject.llm_title).to eq('Install Kong Gateway') }
  end

  describe '#version' do
    context 'when canonical? is true' do
      it { expect(subject.version).to be_nil }
    end

    context 'when release is a valid gem version' do
      let(:page_url) { '/gateway/install/3.9/' }
      let(:page_data) { { 'title' => 'Install Kong Gateway', 'release' => '3.9', 'canonical?' => false } }
      it { expect(subject.version).to eq('v3.9') }
    end

    context 'when release is not a valid gem version' do
      let(:page_url) { '/gateway/install/dev/' }
      let(:page_data) { { 'title' => 'Install Kong Gateway', 'release' => 'dev', 'canonical?' => false } }
      it { expect(subject.version).to eq('dev') }
    end
  end

  describe '#product_or_tool' do
    context 'when product is set' do
      it { expect(subject.product_or_tool).to eq('Kong Gateway') }
    end

    context 'when product is not set and tool is set' do
      let(:page_data) { { 'title' => 'Install Kong Gateway', 'canonical?' => true, 'tools' => ['deck'] } }
      it { expect(subject.product_or_tool).to eq('decK') }
    end

    context 'when neither product nor tool is set' do
      let(:page_data) { { 'title' => 'Install Kong Gateway', 'canonical?' => true } }
      it { expect(subject.product_or_tool).to be_nil }
    end
  end
end
