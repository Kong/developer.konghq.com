# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::Data::Title::APIPage do
  let(:site) { instance_double(Jekyll::Site) }
  let(:page_data) { { 'title' => 'Gateway Admin - EE', 'content_type' => 'api', 'canonical?' => true } }
  let(:page_url) { '/api/gateway/admin-ee/3.14/' }
  let(:page) { instance_double(Jekyll::Page, data: page_data, url: page_url) }

  subject { described_class.new(page:, site:) }

  describe '#title_sections' do
    context 'when url is /api/' do
      let(:page_url) { '/api/' }
      let(:page_data) { { 'title' => 'OpenAPI Specifications' } }
      it { expect(subject.title_sections).to eq(['OpenAPI Specifications']) }
    end

    context 'when canonical? is true' do
      it 'returns title, OpenAPI Specification, and nil version' do
        expect(subject.title_sections).to eq(['Gateway Admin - EE', 'OpenAPI Specification', nil])
      end
    end

    context 'when not canonical and version is a valid gem version' do
      let(:page_data) { { 'title' => 'Gateway Admin - EE', 'content_type' => 'api', 'version' => '13.0' } }
      it { expect(subject.title_sections).to eq(['Gateway Admin - EE', 'OpenAPI Specification', 'v13.0']) }
    end
  end

  describe '#llm_title' do
    context 'when url is /api/' do
      let(:page_url) { '/api/' }
      let(:page_data) { { 'title' => 'OpenAPI Specifications' } }
      it { expect(subject.llm_title).to eq('OpenAPI Specifications') }
    end

    context 'for other api pages' do
      it { expect(subject.llm_title).to eq('Gateway Admin - EE OpenAPI Specification') }
    end

    context 'when content_type is reference - i.e. error page for the API' do
      let(:api_spec) { double('ApiSpec', title: 'Konnect Developer Portal') }
      let(:page_data) do
        { 'title' => 'Errors', 'content_type' => 'reference', 'canonical?' => true, 'api_spec' => api_spec }
      end
      let(:page_url) { '/api/konnect/dev-portal/v2/errors/' }
      it { expect(subject.llm_title).to eq('Konnect Developer Portal - Errors OpenAPI Specification') }
    end
  end

  describe '#version' do
    context 'when canonical? is true' do
      it { expect(subject.version).to be_nil }
    end

    context 'when version is a valid gem version' do
      let(:page_data) { { 'title' => 'Gateway Admin - EE', 'version' => '13.0' } }
      it { expect(subject.version).to eq('v13.0') }
    end

    context 'when version is not a valid gem version' do
      let(:page_data) { { 'title' => 'Gateway Admin - EE', 'version' => 'preview' } }
      it { expect(subject.version).to eq('preview') }
    end
  end

  describe '#title' do
    context 'when url is /api/errors/' do
      let(:page_url) { '/api/errors/' }
      let(:page_data) { { 'title' => 'Errors' } }
      it { expect(subject.title).to eq('Errors') }
    end

    context 'when content_type is api' do
      it { expect(subject.title).to eq('Gateway Admin - EE') }
    end

    context 'when content_type is reference - i.e. error page for the API' do
      let(:api_spec) { double('ApiSpec', title: 'Konnect Developer Portal') }
      let(:page_data) do
        { 'title' => 'Errors', 'content_type' => 'reference', 'canonical?' => true, 'api_spec' => api_spec }
      end
      let(:page_url) { '/api/konnect/dev-portal/v2/errors/' }
      it { expect(subject.title).to eq('Konnect Developer Portal - Errors') }
    end

    context 'when content_type is unrecognised' do
      let(:page_data) { { 'title' => 'Something', 'content_type' => 'other' } }
      it { expect(subject.title).to eq('Something') }
    end
  end
end
