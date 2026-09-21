# frozen_string_literal: true

require 'kramdown'

RSpec.describe 'plugins/example.md' do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  let(:plugin) do
    Jekyll::PluginPages::Plugin.new(
      folder: File.join(PROJECT_ROOT, 'app/_kong_plugins/key-auth'),
      slug: 'key-auth'
    )
  end

  let(:example) { plugin.examples.detect { |e| e.slug == 'enable-key-auth' } }

  let(:credential_example) do
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Key Auth',
      example_formats: %w[deck admin-api konnect-api kic terraform],
      definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
    )
  end

  let(:template) do
    '{% include plugins/example.md %}'
  end

  let(:rendered) do
    render_liquid(template, page: {
                    'example' => example,
                    'credential_example' => credential_example,
                    'min_version' => {}
                  })
  end

  subject(:html) { Capybara::Node::Simple.new(rendered) }

  it 'renders the Consumer and credential section before the plugin configuration section' do
    credential_heading = html.find('h2 a[href="#create-a-consumer-and-credential"]')
    plugin_config_heading = html.find('h2#set-up-the-plugin')

    expect(credential_heading.native).to be < plugin_config_heading.native
  end

  it 'renders the Consumer and credential section heading with its own anchor' do
    expect(html).to have_css('h2 a[href="#create-a-consumer-and-credential"]')
  end
end
