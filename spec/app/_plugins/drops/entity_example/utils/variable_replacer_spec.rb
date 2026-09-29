# frozen_string_literal: true

require_relative '../../../../../spec_helper'
require_relative '../../../../../../app/_plugins/drops/entity_example/utils/variable_replacer'

RSpec.describe Jekyll::Drops::EntityExample::Utils::VariableReplacer::KongctlData do
  describe '.run' do
    subject(:result) { described_class.run(data:, variables:) }

    let(:variables) { {} }

    context 'with a string matching $UPPERCASE_VAR' do
      let(:data) { '$MY_API_KEY' }

      it { is_expected.to eq('__kongctl_env_MY_API_KEY__') }
    end

    context 'with a string that does not match' do
      let(:data) { 'https://example.com' }

      it { is_expected.to eq('https://example.com') }
    end

    context 'with a lowercase $var' do
      let(:data) { '$lowercase_var' }

      it { is_expected.to eq('$lowercase_var') }
    end

    context 'with a hash containing env var values' do
      let(:data) { { 'url' => 'https://example.com', 'key' => '$API_KEY' } }

      it 'transforms only the env var value' do
        expect(result).to eq({ 'url' => 'https://example.com', 'key' => '__kongctl_env_API_KEY__' })
      end
    end

    context 'with an array containing env var strings' do
      let(:data) { ['$FIRST_KEY', 'plain-value', '$SECOND_KEY'] }

      it 'transforms env var entries' do
        expect(result).to eq(['__kongctl_env_FIRST_KEY__', 'plain-value', '__kongctl_env_SECOND_KEY__'])
      end
    end

    context 'with deeply nested data' do
      let(:data) do
        {
          'config' => {
            'query' => {
              'key' => ['$WEATHERAPI_API_KEY']
            }
          }
        }
      end

      it 'transforms the nested env var' do
        expect(result.dig('config', 'query', 'key')).to eq(['__kongctl_env_WEATHERAPI_API_KEY__'])
      end
    end

    context 'with a non-string scalar' do
      let(:data) { { 'timeout' => 60_000, 'enabled' => true } }

      it { is_expected.to eq({ 'timeout' => 60_000, 'enabled' => true }) }
    end

    context 'with a declared variable substituted via ${var}' do
      let(:data) { '${auth_header}' }
      let(:variables) { { 'auth_header' => { 'value' => '$OPENAI_AUTH_HEADER' } } }

      it { is_expected.to eq('__kongctl_env_OPENAI_AUTH_HEADER__') }
    end

    context 'with a secret declared variable substituted via ${var}' do
      let(:data) { '${auth_header}' }
      let(:variables) { { 'auth_header' => { 'value' => '$OPENAI_AUTH_HEADER', 'secret' => true } } }

      it { is_expected.to eq('__kongctl_secret_env_OPENAI_AUTH_HEADER__') }
    end

    context 'with a secret declared variable whose value is not an env var' do
      let(:data) { '${label}' }
      let(:variables) { { 'label' => { 'value' => 'plain-value', 'secret' => true } } }

      it { is_expected.to eq('plain-value') }
    end
  end

  describe '.apply_tags' do
    subject(:result) { described_class.apply_tags(yaml) }

    context 'with a sentinel in a YAML list' do
      let(:yaml) { "- __kongctl_env_MY_API_KEY__\n" }

      it { is_expected.to eq("- !env MY_API_KEY\n") }
    end

    context 'with multiple sentinels' do
      let(:yaml) { "key1: __kongctl_env_FOO__\nkey2: __kongctl_env_BAR__\n" }

      it { is_expected.to eq("key1: !env FOO\nkey2: !env BAR\n") }
    end

    context 'with no sentinels' do
      let(:yaml) { "url: https://example.com\n" }

      it { is_expected.to eq("url: https://example.com\n") }
    end

    context 'with a secret sentinel' do
      let(:yaml) { "value: __kongctl_secret_env_OPENAI_AUTH_HEADER__\n" }

      it { is_expected.to eq("value: !secret {source: !env OPENAI_AUTH_HEADER}\n") }
    end
  end
end
