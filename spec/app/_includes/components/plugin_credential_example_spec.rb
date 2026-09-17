# frozen_string_literal: true

require 'kramdown'

RSpec.describe 'components/plugin_credential_example.html' do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  let(:drop) do
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Key Auth',
      example_formats: %w[deck admin-api konnect-api kic terraform],
      definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
    )
  end

  let(:template) do
    '{% include components/plugin_credential_example.html credential_example=credential_example %}'
  end

  let(:rendered) do
    render_liquid(template, page: { 'output_format' => 'html' }, locals: { 'credential_example' => drop })
  end

  subject(:html) { Capybara::Node::Simple.new(rendered) }

  it 'renders one entity-example container with a format panel per supported tool' do
    expect(html).to have_css('.entity-example', count: 1)
    %w[deck admin-api konnect-api kic terraform].each do |format|
      expect(html).to have_css(%(.entity-example-format-panel[data-format="#{format}"]))
    end
  end

  it 'renders no target selector' do
    expect(html).not_to have_css('select.select-target')
  end

  it 'renders the format selector with an option per supported tool' do
    expect(html).to have_css('select.select-format option', count: 5)
  end

  it 'renders the same lead sentence in every format panel' do
    %w[deck admin-api konnect-api kic terraform].each do |format|
      panel = html.find(%(.entity-example-format-panel[data-format="#{format}"]))
      expect(panel).to have_text('The Key Auth plugin needs a Consumer with a credential attached before it can authenticate requests.')
    end
  end

  it 'gives the container its own anchored heading' do
    expect(html).to have_css('h2 a[href="#create-a-consumer-and-credential"]')
  end
end
