# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductsRenderer do
  subject(:renderer) { described_class.new(build_filter: build_filter) }

  let(:build_filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }

  let(:page) { instance_double(Jekyll::Page, relative_path: relative_path, url: url, data: data, dir: dir) }
  let(:relative_path) { 'gateway/index.md' }
  let(:url) { '/gateway/' }
  let(:data) { { 'products' => ['gateway'] } }
  let(:dir) { '/gateway/' }

  shared_examples 'a product/path filterable method' do
    context 'when the resource is under assets/' do
      let(:relative_path) { 'assets/logo.png' }

      it { is_expected.to be(false) }
    end

    context 'when PAGE_PATHS filtering is active' do
      let(:env) { { 'PAGE_PATHS' => '/gateway/' } }

      context 'and the url matches one of the configured paths' do
        it { is_expected.to be(true) }
      end

      context 'and the url matches none of the configured paths' do
        let(:url) { '/konnect/' }

        it { is_expected.to be(false) }
      end
    end

    context 'when KONG_PRODUCTS filtering is active' do
      let(:env) { { 'KONG_PRODUCTS' => 'gateway' } }

      context 'and the resource data lists that product' do
        it { is_expected.to be(true) }
      end

      context 'and the resource data does not list that product' do
        let(:data) { { 'products' => ['konnect'] } }

        it { is_expected.to be(false) }
      end

      context 'with the wildcard product' do
        let(:env) { { 'KONG_PRODUCTS' => '*' } }
        let(:data) { {} }

        it { is_expected.to be(true) }
      end

      context 'with the always-kept /how-to/ url' do
        let(:url) { '/how-to/' }
        let(:data) { {} }

        it { is_expected.to be(true) }
      end

      context 'with a resource that has no dir method (e.g. a collection document)' do
        let(:page) { instance_double(Jekyll::Document, relative_path: relative_path, url: url, data: data) }
        let(:data) { { 'products' => ['konnect'] } }

        it { is_expected.to be(false) }
      end
    end

    context 'when CONTENT_TYPE filtering is active' do
      let(:env) { { 'CONTENT_TYPE' => 'reference' } }

      context 'and the resource content_type matches' do
        let(:data) { { 'content_type' => 'reference' } }

        it { is_expected.to be(true) }
      end

      context 'and the resource content_type does not match' do
        let(:data) { { 'content_type' => 'how_to' } }

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#read?' do
    subject { renderer.read?(page) }

    it_behaves_like 'a product/path filterable method'
  end

  describe '#render?' do
    subject { renderer.render?(page) }

    it_behaves_like 'a product/path filterable method'
  end
end
