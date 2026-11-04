# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::PluginPages::Generator do
  subject(:generator) { described_class.new(site, build_filter: build_filter) }

  let(:site) { instance_double(Jekyll::Site) }
  let(:build_filter) { Jekyll::BuildFilter.new(env: env) }
  let(:env) { {} }

  describe '#skip_locally?' do
    context 'when the build filter excludes /plugins/' do
      before { allow(Jekyll).to receive(:env).and_return('development') }

      let(:env) { { 'PAGE_PATHS' => '/gateway/' } }

      it { expect(generator.skip_locally?).to be(true) }
    end

    context 'when the build filter does not exclude /plugins/' do
      it { expect(generator.skip_locally?).to be(false) }
    end
  end

  describe '#generate_pages' do
    subject(:generator) { described_class.new(fixture_site, build_filter: Jekyll::BuildFilter.new(env: {})) }

    let(:fixture_site) { JekyllSite.build }
    let(:aigw_url) { '/plugins/fixture-auth/ai-gateway/v2/on-prem/reference/' }
    let(:config_schema) { { 'type' => 'object', 'properties' => { 'key' => { 'type' => 'string' } } } }
    let(:schema_json) { JSON.dump({ 'properties' => { 'protocols' => {}, 'config' => config_schema } }) }

    let(:plugin) do
      Jekyll::PluginPages::Plugin.new(
        folder: File.join(fixture_site.source, '_kong_plugins', 'fixture-auth'),
        slug: 'fixture-auth'
      )
    end

    before do
      allow(Jekyll).to receive(:sites).and_return([fixture_site])
      fixture_site.data['kong_plugins'] ||= {}
      fixture_site.data['entity_examples'] = {
        'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true)
      }
      stub_const('Jekyll::Drops::Plugins::Schema::SCHEMAS_BASE', fixture_schemas_base)
      stub_const('Jekyll::Drops::Plugins::AIGWPolicySchema::FILE_INDEX',
                 { 'fixtureauth.json' => '/fake/FixtureAuth.json' })
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('/fake/FixtureAuth.json').and_return(schema_json)
    end

    after do
      Jekyll::Drops::Plugins::Schema::FILE_INDEX
        .reject { |dir, _| dir.start_with?(fixture_schemas_base) }
        .each_key { |dir| Jekyll::Drops::Plugins::Schema::FILE_INDEX.delete(dir) }
    end

    let(:fixture_schemas_base) { File.join(fixture_site.source, '_schemas/gateway/plugins') }

    context 'when the plugin is in the aigw_onprem_plugin_reference config list' do
      before { fixture_site.config['aigw_onprem_plugin_reference'] = ['fixture-auth'] }

      it 'adds the AIGW on-prem reference page to the site' do
        generator.generate_pages(plugin)

        expect(fixture_site.pages.map(&:url)).to include(aigw_url)
      end
    end

    context 'when the plugin is not in the aigw_onprem_plugin_reference config list' do
      before { fixture_site.config['aigw_onprem_plugin_reference'] = ['ai-proxy-advanced'] }

      it 'does not add the AIGW on-prem reference page to the site' do
        generator.generate_pages(plugin)

        expect(fixture_site.pages.map(&:url)).not_to include(aigw_url)
      end
    end
  end
end
