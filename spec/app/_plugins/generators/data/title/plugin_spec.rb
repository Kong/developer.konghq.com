# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::Data::Title::Plugin do
  let(:site) { instance_double(Jekyll::Site) }
  let(:plugin) { double('Plugin', name: 'Rate Limiting') }
  let(:page_data) { { 'title' => 'Rate Limiting', 'plugin?' => true, 'plugin' => plugin } }
  let(:page_url) { '/plugins/rate-limiting/' }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }

  let(:overview_data) { { 'title' => 'Rate Limiting', 'plugin?' => true, 'overview?' => true, 'plugin' => plugin } }
  let(:reference_data) do
    { 'title' => 'Rate Limiting', 'plugin?' => true, 'reference?' => true, 'canonical?' => true,
      'plugin' => plugin }
  end
  let(:changelog_data) do
    { 'title' => 'Rate Limiting', 'plugin?' => true, 'changelog?' => true, 'plugin' => plugin, 'canonical?' => true }
  end
  let(:api_reference_data) do
    { 'title' => 'Rate Limiting', 'plugin?' => true, 'api_reference?' => true, 'plugin' => plugin }
  end
  let(:example_data) do
    { 'title' => 'Rate Limiting', 'plugin?' => true, 'example?' => true, 'example_title' => 'Basic Config',
      'plugin' => plugin }
  end

  subject { described_class.new(page:, site:) }

  describe '#title_sections' do
    context 'when not a plugin page' do
      let(:page_url) { '/plugins/' }
      let(:page_data) { { 'title' => 'Plugins Hub' } }
      it { expect(subject.title_sections).to eq(['Plugins Hub']) }
    end

    context 'when overview?' do
      let(:page_data) { overview_data }
      it { expect(subject.title_sections).to eq(['Rate Limiting', nil, nil, 'Plugin']) }
    end

    context 'when reference? and canonical?' do
      let(:page_url) { '/plugins/rate-limiting/reference/' }
      let(:page_data) { reference_data }

      it { expect(subject.title_sections).to eq(['Rate Limiting', 'Configuration Reference', nil, 'Plugin']) }
    end

    context 'when reference? and not canonical?' do
      let(:page_url) { '/plugins/rate-limiting/reference/3.9/' }
      let(:page_data) do
        { 'title' => 'Rate Limiting', 'plugin?' => true, 'reference?' => true, 'release' => '3.9',
          'plugin' => plugin, 'canonical?' => false }
      end
      it { expect(subject.title_sections).to eq(['Rate Limiting', 'Configuration Reference', 'v3.9', 'Plugin']) }
    end

    context 'when changelog?' do
      let(:page_url) { '/plugins/rate-limiting/changelog/' }
      let(:page_data) { changelog_data }
      it { expect(subject.title_sections).to eq(['Rate Limiting', 'Changelog', nil, 'Plugin']) }
    end

    context 'when api_reference?' do
      let(:page_url) { '/plugins/rate-limiting/api/' }
      let(:page_data) { api_reference_data }
      it { expect(subject.title_sections).to eq(['Rate Limiting', 'OpenAPI Specification', nil, 'Plugin']) }
    end

    context 'when example?' do
      let(:page_url) { '/plugins/rate-limiting/examples/basic-config/' }
      let(:page_data) { example_data }
      it { expect(subject.llm_title).to eq('Rate Limiting: Basic Config') }
    end
  end

  describe '#llm_title' do
    context 'when not a plugin page' do
      let(:page_url) { '/plugins/' }
      let(:page_data) { { 'title' => 'Plugins Hub' } }
      it { expect(subject.llm_title).to eq('Plugins Hub') }
    end

    context 'when example?' do
      let(:page_url) { '/plugins/rate-limiting/examples/basic-config/' }

      let(:page_data) { example_data }
      it { expect(subject.llm_title).to eq('Rate Limiting: Basic Config') }
    end

    context 'when overview?' do
      let(:page_data) { overview_data }
      it { expect(subject.llm_title).to eq('Rate Limiting Plugin') }
    end

    context 'when reference?' do
      let(:page_data) { reference_data }
      it { expect(subject.llm_title).to eq('Rate Limiting Plugin Configuration Reference') }
    end

    context 'when changelog?' do
      let(:page_data) { changelog_data }
      it { expect(subject.llm_title).to eq('Rate Limiting Plugin Changelog') }
    end
  end

  describe '#version' do
    context 'when not reference?' do
      it { expect(subject.version).to be_nil }
    end

    context 'when reference? and canonical?' do
      let(:page_data) { reference_data }
      it { expect(subject.version).to be_nil }
    end

    context 'when reference?, not canonical?, and release is a valid gem version' do
      let(:page_data) { { 'plugin?' => true, 'reference?' => true, 'release' => '3.9.0', 'plugin' => plugin } }
      it { expect(subject.version).to eq('v3.9.0') }
    end

    context 'when release is not a valid gem version' do
      let(:page_data) { { 'plugin?' => true, 'reference?' => true, 'release' => 'unreleased', 'plugin' => plugin } }
      it { expect(subject.version).to eq('unreleased') }
    end
  end

  describe '#title' do
    context 'when overview?' do
      let(:page_data) { overview_data }
      it { expect(subject.title).to be_nil }
    end

    context 'when example?' do
      let(:page_data) { example_data }
      it { expect(subject.title).to be_nil }
    end

    context 'when reference?' do
      let(:page_data) { reference_data }
      it { expect(subject.title).to eq('Configuration Reference') }
    end

    context 'when changelog?' do
      let(:page_data) { changelog_data }
      it { expect(subject.title).to eq('Changelog') }
    end

    context 'when api_reference?' do
      let(:page_data) { api_reference_data }
      it { expect(subject.title).to eq('OpenAPI Specification') }
    end
  end

  describe '#name' do
    context 'when not example?' do
      it { expect(subject.name).to eq('Rate Limiting') }
    end

    context 'when example?' do
      let(:page_data) { example_data }
      it { expect(subject.name).to eq('Rate Limiting: Basic Config') }
    end
  end
end
