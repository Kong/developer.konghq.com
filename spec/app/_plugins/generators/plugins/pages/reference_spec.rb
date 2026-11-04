# frozen_string_literal: true

require_relative '../../../../../spec_helper'

RSpec.describe Jekyll::PluginPages::Pages::Reference do
  let(:site) { JekyllSite.build }
  let(:aigw_url) { '/plugins/fixture-auth/ai-gateway/v2/on-prem/reference/' }

  let(:plugin) do
    Jekyll::PluginPages::Plugin.new(
      folder: File.join(site.source, '_kong_plugins', 'fixture-auth'),
      slug: 'fixture-auth'
    )
  end

  let(:page) { described_class.new(plugin:, file: File.join(plugin.folder, 'reference.md')) }

  before do
    allow(Jekyll).to receive(:sites).and_return([site])
    site.data['entity_examples'] = {
      'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true)
    }
    stub_const('Jekyll::Drops::Plugins::Schema::SCHEMAS_BASE', File.join(site.source, '_schemas/gateway/plugins'))
  end

  after do
    Jekyll::Drops::Plugins::Schema::FILE_INDEX
      .reject { |dir, _| dir.start_with?(site.source) }
      .each_key { |dir| Jekyll::Drops::Plugins::Schema::FILE_INDEX.delete(dir) }
  end

  describe '#data' do
    context 'when the plugin is in the aigw_onprem_plugin_reference config list' do
      before { site.config['aigw_onprem_plugin_reference'] = ['fixture-auth'] }

      it 'carries the AIGW on-prem URL for the extra dropdown option' do
        expect(page.data['aigw_onprem_url']).to eq(aigw_url)
      end
    end

    context 'when the plugin is not in the aigw_onprem_plugin_reference config list' do
      before { site.config['aigw_onprem_plugin_reference'] = ['ai-proxy-advanced'] }

      it 'does not carry the AIGW on-prem URL key' do
        expect(page.data).not_to have_key('aigw_onprem_url')
      end
    end
  end
end
