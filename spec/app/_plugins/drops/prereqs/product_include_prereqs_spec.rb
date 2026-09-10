# frozen_string_literal: true

require_relative '../../../../spec_helper'
RSpec.describe Jekyll::Drops::ProductIncludePrereqs do
  let(:product_includes) do
    [
      'app/_includes/prereqs/products/mesh.md',
      'app/_includes/prereqs/products/mesh/v1.md',
      'app/_includes/prereqs/products/kic.md',
      'app/_includes/prereqs/products/ai-gateway.md'
    ]
  end
  let(:products_data) do
    {
      'mesh' => {
        'previous_major_url_segment' => 'v<major>',
        'releases' => [{ 'version' => '1.0.0', 'release' => '1.0' },
                       { 'version' => '2.0.0', 'release' => '2.2', 'latest' => true }]
      },
      'ai-gateway' => {
        'previous_major_url_segment' => 'v<major>',
        'releases' => [{ 'release' => '1.0' }, { 'release' => '2.0', 'latest' => true }]
      },
      'kic' => {
        'releases' => [{ 'release' => '3.4' }, { 'release' => '3.5', 'latest' => true }]
      }
    }
  end
  let(:major_version) { nil }

  before { stub_const("#{described_class}::PRODUCT_INCLUDES", product_includes) }

  subject { described_class.new(products:, major_version:, products_data:) }

  context 'not including ai-gateway' do
    context 'without major_version' do
      context 'it returns a map of products to their include files' do
        let(:products) { %w[mesh kic] }

        it 'returns a hash mapping products to their include files' do
          expect(subject.products_include_map)
            .to eq({ 'mesh' => 'prereqs/products/mesh.md', 'kic' => 'prereqs/products/kic.md' })
        end
      end
    end

    context 'with major_version' do
      context 'it returns a map of products to their include files - scoped to the major versions' do
        let(:products) { %w[mesh kic] }
        let(:major_version) { { 'mesh' => 1 } }

        it 'returns a hash mapping products to their include files' do
          expect(subject.products_include_map)
            .to eq({ 'mesh' => 'prereqs/products/mesh/v1.md', 'kic' => 'prereqs/products/kic.md' })
        end
      end
    end
  end

  context 'including ai-gateway' do
    context 'with major_version = 1' do
      let(:products) { %w[mesh ai-gateway kic] }
      let(:major_version) { { 'ai-gateway' => 1 } }

      it 'returns a hash mapping products to their include files - without ai-gateway' do
        expect(subject.products_include_map)
          .to eq({ 'mesh' => 'prereqs/products/mesh.md', 'kic' => 'prereqs/products/kic.md' })
      end
    end

    context 'without major_version' do
      let(:products) { %w[mesh ai-gateway kic] }

      it 'returns a hash mapping products to their include files' do
        expect(subject.products_include_map)
          .to eq({ 'mesh' => 'prereqs/products/mesh.md', 'kic' => 'prereqs/products/kic.md',
                   'ai-gateway' => 'prereqs/products/ai-gateway.md' })
      end
    end
  end

  context 'including gateway' do
    let(:products) { %w[gateway mesh] }

    it 'does not include gateway' do
      expect(subject.products_include_map).to eq({ 'mesh' => 'prereqs/products/mesh.md' })
    end
  end
end
