# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Drops::EntityExamplesData do
  let(:anthropic_example) do
    { 'type' => 'anthropic', 'name' => 'new-test-anthropic',
      'display_name' => 'new-test-anthropic', 'auth' => { 'type' => 'basic' } }
  end
  let(:anthropic_example_v1) do
    { 'type' => 'anthropic', 'name' => 'old-test-anthropic',
      'display_name' => 'old-test-anthropic', 'auth' => { 'type' => 'basic' } }
  end

  let(:entity_examples) do
    {
      'gateway' => {
        'services' => {
          'basic' => { 'name' => 'example-service', 'url' => 'http://example.com' },
          'advanced' => { 'name' => 'advanced-service', 'url' => 'http://advanced.com' }
        },
        'routes' => {
          'basic' => { 'name' => 'example-route', 'paths' => ['/'] }
        }
      },
      'ai-gateway' => {
        'providers' => {
          'anthropic' => anthropic_example
        },
        'v1' => {
          'providers' => {
            'anthropic' => anthropic_example_v1
          }
        }
      }
    }
  end
  let(:entities) { YAML.safe_load(entities_config) }
  let(:major) { nil }
  let(:product_data) { { 'name' => 'Kong Gateway', 'releases' => [{ 'release' => '3.4.', 'latest' => true }] } }

  subject { described_class.new(product:, entities:, entity_examples:, major:, product_data:) }

  describe '#to_h' do
    context 'a product without major versions' do
      let(:product_data) { { 'name' => 'Kong Gateway', 'releases' => [{ 'release' => '3.4.', 'latest' => true }] } }
      let(:product) { 'gateway' }
      let(:entities_config) do
        <<~YAML
          services:
            - basic
            - advanced
          routes:
            - basic
        YAML
      end

      context 'with valid entity examples' do
        it 'returns a hash mapping entity types to their examples' do
          expect(subject.to_h).to eq(
            'services' => [
              { 'name' => 'example-service', 'url' => 'http://example.com' },
              { 'name' => 'advanced-service', 'url' => 'http://advanced.com' }
            ],
            'routes' => [
              { 'name' => 'example-route', 'paths' => ['/'] }
            ]
          )
        end
      end

      context 'with no entities' do
        let(:entities) { [] }

        it { expect(subject.to_h).to eq({}) }
      end

      context 'when an entity example file is missing' do
        let(:entities_config) do
          <<~YAML
            services:
              - missing
          YAML
        end
        it 'raises an ArgumentError with the expected path' do
          expect { subject.to_h }.to raise_error(
            ArgumentError,
            'Missing entity_example file in app/_data/entity_examples/gateway/services/missing.{yml,yaml}'
          )
        end
      end

      context 'when the product has no entity examples' do
        let(:product) { 'unknown' }

        it 'raises an ArgumentError' do
          expect { subject.to_h }.to raise_error(ArgumentError, /unknown/)
        end
      end
    end

    context 'a product with major versions' do
      let(:product_data) do
        {
          'name' => 'AI Gateway',
          'previous_major_url_segment' => 'v<major>',
          'releases' => [{ 'release' => '2.0.', 'latest' => true }, { 'release' => '1.0.' }]
        }
      end
      let(:product) { 'ai-gateway' }
      let(:entities_config) do
        <<~YAML
          providers:
            - anthropic
        YAML
      end

      context 'a page without major_version' do
        context 'when the entity_example file exists' do
          it 'returns the entity example data from the latest version' do
            expect(subject.to_h).to eq(
              'providers' => [anthropic_example]
            )
          end
        end

        context 'when the entity_example file does not exist' do
          let(:entities_config) do
            <<~YAML
              providers:
                - missing
            YAML
          end
          it 'raises an ArgumentError with the expected path' do
            expect { subject.to_h }.to raise_error(
              ArgumentError,
              'Missing entity_example file in app/_data/entity_examples/ai-gateway/providers/missing.{yml,yaml}'
            )
          end
        end
      end

      context 'a page with major_version' do
        let(:major) { 1 }

        context 'when the entity_example file exists' do
          it 'returns the entity example data scoped to the major version' do
            expect(subject.to_h).to eq(
              'providers' => [anthropic_example_v1]
            )
          end
        end

        context 'when an entity example file is missing' do
          let(:major) { 2 }
          it 'raises an ArgumentError with the expected path' do
            expect { subject.to_h }.to raise_error(
              ArgumentError,
              'Missing entity_example file in app/_data/entity_examples/ai-gateway/v2/providers/anthropic.{yml,yaml}'
            )
          end
        end
      end
    end
  end
end
