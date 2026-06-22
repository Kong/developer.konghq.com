# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe Jekyll::AIGatewayPolicyPages::Policy do
  let(:folder) { '/app/_ai_gateway_policies/my-policy' }
  let(:slug) { 'my-policy' }

  let(:plugin_metadata) do
    { 'title' => 'My Policy', 'name' => 'my-policy', 'description' => 'A policy', 'icon' => 'my-policy.svg' }
  end
  let(:plugin_drop) { double('PluginDrop', metadata: plugin_metadata) }

  let(:config_schema) { { 'type' => 'object', 'properties' => {} } }
  let(:schema_obj) { double('Schema', as_json: { 'properties' => { 'config' => config_schema, 'consumer' => {} } }) }

  let(:api_plugin_page) do
    instance_double(Jekyll::PluginPages::Pages::Overview, data: { 'plugin' => plugin_drop, 'schema' => schema_obj })
  end

  let(:site_config) { { 'ai_gateway_policies' => { 'metadata' => { 'keep' => %w[title name description icon] } } } }
  let(:site) { instance_double(Jekyll::Site, data: { 'kong_plugins' => { slug => api_plugin_page } }, config: site_config) }

  let(:release_info) do
    instance_double(
      Jekyll::ReleaseInfo::Product,
      releases: [],
      latest_available_release: nil,
      latest_release_in_range: nil,
      unreleased?: false,
      min_release: nil
    )
  end

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    allow(Jekyll::ReleaseInfo::Product).to receive(:new).and_return(release_info)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(File.join(folder, 'index.md'))
                                 .and_return("---\nproducts:\n  - ai-gateway\n---\n")
  end

  subject(:policy) { described_class.new(folder:, slug:) }

  describe '#schema' do
    it 'wraps the config properties from the api plugin schema' do
      expect(policy.schema).to eq({ 'properties' => { 'config' => config_schema } })
    end
  end

  describe '#examples' do
    it { expect(policy.examples).to eq([]) }
  end

  describe '#metadata' do
    subject(:metadata) { policy.metadata }

    it 'includes plugin metadata sliced by the configured keep keys' do
      expect(metadata).to include('title' => 'My Policy', 'name' => 'my-policy',
                                  'description' => 'A policy', 'icon' => 'my-policy.svg')
    end

    it 'does not include plugin metadata keys outside the keep list' do
      plugin_metadata['unlisted_key'] = 'should not appear'
      expect(metadata).not_to have_key('unlisted_key')
    end

    it 'includes the schema' do
      expect(metadata['schema']).to eq({ 'properties' => { 'config' => config_schema } })
    end

    it 'merges frontmatter from index.md via super' do
      expect(metadata['products']).to eq(['ai-gateway'])
    end
  end
end
