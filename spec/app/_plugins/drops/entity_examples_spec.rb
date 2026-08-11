# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Jekyll::Drops::EntityExamples do
  let(:config) do
    { 'entities' => entities, 'deck_flags' => [], 'variables' => {} }
  end

  subject(:drop) { described_class.new(config:, format: 'deck') }

  describe '#data' do
    context 'when a plugin condition contains double quotes' do
      let(:entities) do
        { 'plugins' => [{ 'name' => 'replaceme', 'condition' => '!http.path.contains("skip")' }] }
      end

      it 'renders condition as a double-quoted YAML scalar' do
        expect(drop.data).to include('condition: "!http.path.contains(\"skip\")"')
      end

      it 'does not render condition as a single-quoted YAML scalar' do
        expect(drop.data).not_to match(/condition: '/)
      end
    end

    context 'when a plugin condition contains no special characters' do
      let(:entities) do
        { 'plugins' => [{ 'name' => 'example', 'condition' => 'http.path == "/api"' }] }
      end

      it 'leaves the condition as-is' do
        expect(drop.data).not_to match(/condition: '/)
      end
    end

    context 'when a non-condition field would be single-quoted by Psych' do
      let(:entities) do
        { 'plugins' => [{ 'name' => 'example', 'other_field' => '!value with "quotes"' }] }
      end

      it 'does not requote the non-condition field' do
        expect(drop.data).to include("other_field: '!value with \"quotes\"'")
      end
    end
  end
end
