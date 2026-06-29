# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::Data::Title::Policy do
  let(:site) { instance_double(Jekyll::Site) }
  let(:plugin) { double('Plugin', name: 'MeshRetry') }
  let(:page_data) { { 'title' => 'MeshRetry', 'plugin?' => true, 'plugin' => plugin } }
  let(:page_url) { '/mesh/policies/meshretry/' }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }

  let(:overview_data) do
    { 'title' => 'MeshRetry', 'plugin?' => true, 'overview?' => true, 'plugin' => plugin, 'canonical?' => true }
  end
  let(:reference_data) do
    { 'title' => 'MeshRetry', 'plugin?' => true, 'reference?' => true, 'canonical?' => true,
      'plugin' => plugin }
  end
  let(:example_data) do
    { 'title' => 'MeshRetry', 'plugin?' => true, 'example?' => true, 'example_title' => 'HTTP Retry',
      'plugin' => plugin, 'canonical?' => true }
  end

  subject { described_class.new(page:, site:) }

  describe '#title_sections' do
    context 'when not a plugin page' do
      let(:page_url) { '/mesh/policies/' }
      let(:page_data) { { 'title' => 'Policies' } }
      it { expect(subject.title_sections).to eq(['Policies']) }
    end

    context 'when overview?' do
      let(:page_data) { overview_data }
      it { expect(subject.title_sections).to eq(['MeshRetry', nil, nil, 'Policy']) }
    end

    context 'when reference? and canonical?' do
      let(:page_url) { '/mesh/policies/meshretry/reference/' }
      let(:page_data) { reference_data }
      it { expect(subject.title_sections).to eq(['MeshRetry', 'Configuration Reference', nil, 'Policy']) }
    end

    context 'when reference? and not canonical?' do
      let(:page_url) { '/mesh/policies/meshretry/reference/2.8/' }
      let(:page_data) do
        { 'title' => 'MeshRetry', 'plugin?' => true, 'reference?' => true, 'release' => '2.8',
          'plugin' => plugin, 'canonical?' => false }
      end
      it { expect(subject.title_sections).to eq(['MeshRetry', 'Configuration Reference', 'v2.8', 'Policy']) }
    end

    context 'when example?' do
      let(:page_url) { '/mesh/policies/meshretry/examples/http-retry/' }
      let(:page_data) { example_data }
      it { expect(subject.llm_title).to eq('MeshRetry: HTTP Retry') }
    end
  end

  describe '#llm_title' do
    context 'when not a plugin page' do
      let(:page_url) { '/mesh/policies/' }
      let(:page_data) { { 'title' => 'Policies' } }
      it { expect(subject.llm_title).to eq('Policies') }
    end

    context 'when example?' do
      let(:page_url) { '/mesh/policies/meshretry/examples/http-retry/' }
      let(:page_data) { example_data }
      it { expect(subject.llm_title).to eq('MeshRetry: HTTP Retry') }
    end

    context 'when overview?' do
      let(:page_data) { overview_data }
      it { expect(subject.llm_title).to eq('MeshRetry Policy') }
    end

    context 'when reference?' do
      let(:page_data) { reference_data }
      it { expect(subject.llm_title).to eq('MeshRetry Policy Configuration Reference') }
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
      let(:page_data) { { 'plugin?' => true, 'reference?' => true, 'release' => '2.8', 'plugin' => plugin } }
      it { expect(subject.version).to eq('v2.8') }
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

    context 'when no special flag is set' do
      let(:page_data) { { 'plugin?' => true, 'plugin' => plugin } }
      it { expect(subject.title).to eq('Configuration Reference') }
    end
  end

  describe '#name' do
    context 'when not example?' do
      it { expect(subject.name).to eq('MeshRetry') }
    end

    context 'when example?' do
      let(:page_data) { example_data }
      it { expect(subject.name).to eq('MeshRetry: HTTP Retry') }
    end
  end
end
