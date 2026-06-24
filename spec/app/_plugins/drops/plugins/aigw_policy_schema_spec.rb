# frozen_string_literal: true

require 'json'
require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Drops::Plugins::AIGWPolicySchema do
  let(:slug) { 'openid-connect' }
  let(:config_schema) { { 'type' => 'object', 'properties' => { 'issuer' => { 'type' => 'string' } } } }
  let(:schema_json) { JSON.dump({ 'properties' => { 'config' => config_schema, 'protocols' => {} } }) }
  let(:site) { instance_double(Jekyll::Site, source: '/app') }

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    allow(File).to receive(:read)
      .with('/app/_schemas/ai-gateway/policies/OpenidConnect.json')
      .and_return(schema_json)
  end

  subject(:drop) { described_class.new(slug:) }

  describe '#as_json' do
    it 'returns a hash with only the config properties wrapped under properties.config' do
      expect(drop.as_json).to eq({ 'properties' => { 'config' => config_schema } })
    end

    it 'excludes non-config top-level schema properties' do
      expect(drop.as_json.dig('properties')).not_to have_key('protocols')
    end
  end

  describe 'slug-to-filename conversion' do
    context 'with a hyphenated slug' do
      it 'reads the correctly capitalized filename' do
        expect(File).to receive(:read)
          .with('/app/_schemas/ai-gateway/policies/OpenidConnect.json')
          .and_return(schema_json)
        drop.as_json
      end
    end

    context 'with a single-word slug' do
      let(:slug) { 'cors' }

      before do
        allow(File).to receive(:read)
          .with('/app/_schemas/ai-gateway/policies/Cors.json')
          .and_return(schema_json)
      end

      it 'reads the capitalized filename' do
        expect(File).to receive(:read)
          .with('/app/_schemas/ai-gateway/policies/Cors.json')
          .and_return(schema_json)
        drop.as_json
      end
    end

    context 'with a three-segment slug' do
      let(:slug) { 'ai-rate-limiting-advanced' }

      before do
        allow(File).to receive(:read)
          .with('/app/_schemas/ai-gateway/policies/AiRateLimitingAdvanced.json')
          .and_return(schema_json)
      end

      it 'capitalizes each segment' do
        expect(File).to receive(:read)
          .with('/app/_schemas/ai-gateway/policies/AiRateLimitingAdvanced.json')
          .and_return(schema_json)
        drop.as_json
      end
    end
  end
end
