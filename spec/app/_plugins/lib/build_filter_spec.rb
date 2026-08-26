# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::BuildFilter do
  subject(:filter) { described_class.new(env: env) }

  let(:env) { {} }

  describe '#products' do
    context 'when KONG_PRODUCTS is set' do
      let(:env) { { 'KONG_PRODUCTS' => 'ai-gateway,gateway' } }

      it 'returns the split product slugs' do
        expect(filter.products).to eq(%w[ai-gateway gateway])
      end
    end

    context 'when KONG_PRODUCTS is not set' do
      it { expect(filter.products).to eq([]) }
    end
  end

  describe '#content_type' do
    context 'when CONTENT_TYPE is set with spaces around commas' do
      let(:env) { { 'CONTENT_TYPE' => 'reference , how_to' } }

      it 'splits, strips, and rejects empty entries' do
        expect(filter.content_type).to eq(%w[reference how_to])
      end
    end

    context 'when CONTENT_TYPE is not set' do
      it { expect(filter.content_type).to eq([]) }
    end
  end

  describe '#page_paths' do
    context 'when PAGE_PATHS is set with spaces around commas' do
      let(:env) { { 'PAGE_PATHS' => '/plugins/ , /gateway/entities/' } }

      it 'splits, strips, and rejects empty entries' do
        expect(filter.page_paths).to eq(['/plugins/', '/gateway/entities/'])
      end
    end

    context 'when PAGE_PATHS is not set' do
      it { expect(filter.page_paths).to eq([]) }
    end
  end

  describe '#filtered?' do
    context 'when not in development' do
      before { allow(Jekyll).to receive(:env).and_return('test') }

      let(:env) { { 'KONG_PRODUCTS' => 'ai-gateway', 'PAGE_PATHS' => '/plugins/' } }

      it { expect(filter.filtered?).to be(false) }
    end

    context 'when in development' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      context 'when neither var is set' do
        it { expect(filter.filtered?).to be(false) }
      end

      context 'when only KONG_PRODUCTS is set' do
        let(:env) { { 'KONG_PRODUCTS' => 'ai-gateway' } }

        it { expect(filter.filtered?).to be(true) }
      end

      context 'when only PAGE_PATHS is set' do
        let(:env) { { 'PAGE_PATHS' => '/plugins/' } }

        it { expect(filter.filtered?).to be(true) }
      end

      context 'when only CONTENT_TYPE is set' do
        let(:env) { { 'CONTENT_TYPE' => 'reference' } }

        it { expect(filter.filtered?).to be(true) }
      end

      context 'when all three are set' do
        let(:env) { { 'KONG_PRODUCTS' => 'ai-gateway', 'PAGE_PATHS' => '/plugins/', 'CONTENT_TYPE' => 'reference' } }

        it { expect(filter.filtered?).to be(true) }
      end
    end
  end

  describe '#path_included?' do
    let(:env) { { 'PAGE_PATHS' => '/plugins/,/gateway/entities/' } }

    it 'returns true for a url starting with one of the configured paths' do
      expect(filter.path_included?('/plugins/acme/')).to be(true)
    end

    it 'returns false for a url matching none of the configured paths' do
      expect(filter.path_included?('/konnect/')).to be(false)
    end
  end

  describe '#excludes_prefix?' do
    context 'when not in development' do
      before { allow(Jekyll).to receive(:env).and_return('test') }

      let(:env) { { 'PAGE_PATHS' => '/gateway/entities/' } }

      it { expect(filter.excludes_prefix?('/plugins/')).to be(false) }
    end

    context 'when in development' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      context 'when PAGE_PATHS is not set' do
        it { expect(filter.excludes_prefix?('/plugins/')).to be(false) }
      end

      context 'when PAGE_PATHS includes the prefix' do
        let(:env) { { 'PAGE_PATHS' => '/plugins/,/gateway/' } }

        it { expect(filter.excludes_prefix?('/plugins/')).to be(false) }
      end

      context 'when PAGE_PATHS is set but excludes the prefix' do
        let(:env) { { 'PAGE_PATHS' => '/gateway/entities/' } }

        it { expect(filter.excludes_prefix?('/plugins/')).to be(true) }
      end
    end
  end

  describe '.current' do
    it 'memoizes a single instance' do
      expect(described_class.current).to equal(described_class.current)
    end
  end
end
