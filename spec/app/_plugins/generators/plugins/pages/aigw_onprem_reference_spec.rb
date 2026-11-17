# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::PluginPages::Pages::AIGatewayOnPremReference do
  let(:site) { JekyllSite.build }
  let(:aigw_url) { '/plugins/fixture-auth/ai-gateway/v2/on-prem/reference/' }

  let(:plugin) do
    Jekyll::PluginPages::Plugin.new(
      folder: File.join(site.source, '_kong_plugins', 'fixture-auth'),
      slug: 'fixture-auth'
    )
  end

  let(:page) { described_class.new(plugin:, file: File.join(plugin.folder, 'reference.md')) }

  let(:config_schema) { { 'type' => 'object', 'properties' => { 'key' => { 'type' => 'string' } } } }
  let(:schema_json) { JSON.dump({ 'properties' => { 'protocols' => {}, 'config' => config_schema } }) }

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    site.data['entity_examples'] = {
      'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true)
    }
    stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
               { 'fixtureauth.json' => '/fake/FixtureAuth.json' })
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('/fake/FixtureAuth.json').and_return(schema_json)
  end

  describe '.url' do
    it 'nests the page under the plugin path with the AIGW on-prem version segment' do
      expect(described_class.url(plugin)).to eq(aigw_url)
    end
  end

  describe '#schema' do
    it 'wires the AIGW policy schema drop for the plugin slug' do
      expect(page.data['schema']).to be_a(Jekyll::Drops::Plugins::AIGWPolicySchema)
      expect(page.data['schema'].as_json).to eq('properties' => { 'config' => config_schema })
    end
  end

  describe '#data' do
    it 'renders through the same layout as the classic reference page' do
      expect(page.data['layout']).to eq('plugins/reference')
      expect(page.data['content_type']).to eq('reference')
      expect(page.data['reference?']).to be(true)
    end

    it 'excludes the page from the reference versioner' do
      expect(page.data['skip_versioner']).to be(true)
    end

    it 'sets the flag the aside gate and title branch key on' do
      expect(page.data['aigw_onprem_plugin_reference?']).to be(true)
    end

    it 'points the extra dropdown option at its own URL' do
      expect(page.data['aigw_onprem_url']).to eq(aigw_url)
    end

    it 'sets no release, so no release option self-selects' do
      expect(page.data).not_to have_key('release')
    end

    it 'is not versioned' do
      expect(page.data).not_to have_key('versioned')
    end

    it 'is canonical for its own URL' do
      expect(page.data['canonical?']).to be(true)
      expect(page.data['canonical_url']).to eq(aigw_url)
    end

    it 'builds the dropdown from the classic reference URL and the plugin releases' do
      dropdown = page.data['releases_dropdown']

      expect(dropdown).to be_a(Jekyll::Drops::ReleasesDropdown)
      expect(dropdown.base_url).to eq('/plugins/fixture-auth/reference/')
      expect(dropdown.options.map(&:url)).to eq(
        ['/plugins/fixture-auth/reference/', '/plugins/fixture-auth/reference/3.9/']
      )
    end
  end
end
