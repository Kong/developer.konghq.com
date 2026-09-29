# frozen_string_literal: true

require 'json'
require_relative '../../../../spec_helper'

RSpec.describe Jekyll::Drops::Plugins::AIGWPolicySchema do
  let(:slug) { 'openid-connect' }
  let(:config_schema) { { 'type' => 'object', 'properties' => { 'issuer' => { 'type' => 'string' } } } }
  let(:schema_json) { JSON.dump({ 'properties' => { 'config' => config_schema, 'protocols' => {} } }) }

  before do
    stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
               { 'openidconnect.json' => '/fake/OpenidConnect.json' })
    allow(File).to receive(:read).with('/fake/OpenidConnect.json').and_return(schema_json)
  end

  subject(:drop) { described_class.new(slug:) }

  describe '#as_json' do
    it 'wraps config properties under properties.config' do
      expect(drop.as_json).to eq({ 'properties' => { 'config' => config_schema } })
    end

    it 'excludes non-config top-level schema properties' do
      expect(drop.as_json.dig('properties')).not_to have_key('protocols')
    end

    it 'memoizes the result, reading the file only once' do
      2.times { drop.as_json }
      expect(File).to have_received(:read).with('/fake/OpenidConnect.json').once
    end
  end

  describe 'slug-to-filename conversion' do
    context 'with a single-word slug' do
      let(:slug) { 'cors' }

      before do
        stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
                   { 'cors.json' => '/fake/Cors.json' })
        allow(File).to receive(:read).with('/fake/Cors.json').and_return(schema_json)
      end

      it { expect(drop.as_json).to eq({ 'properties' => { 'config' => config_schema } }) }
    end

    context 'with a four-segment slug' do
      let(:slug) { 'ai-rate-limiting-advanced' }

      before do
        stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
                   { 'airatelimitingadvanced.json' => '/fake/AiRateLimitingAdvanced.json' })
        allow(File).to receive(:read).with('/fake/AiRateLimitingAdvanced.json').and_return(schema_json)
      end

      it { expect(drop.as_json).to eq({ 'properties' => { 'config' => config_schema } }) }
    end
  end

  describe 'case-insensitive file lookup' do
    context 'when the file on disk uses all-caps (ACL.json) but slug produces Acl' do
      let(:slug) { 'acl' }

      before do
        stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
                   { 'acl.json' => '/fake/ACL.json' })
        allow(File).to receive(:read).with('/fake/ACL.json').and_return(schema_json)
      end

      it 'finds and reads the file' do
        expect(drop.as_json).to eq({ 'properties' => { 'config' => config_schema } })
      end
    end
  end

  describe 'missing schema file' do
    before do
      stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX', {})
    end

    it 'raises ArgumentError mentioning the slug' do
      expect { drop.as_json }.to raise_error(ArgumentError, /openid-connect/)
    end
  end
end
