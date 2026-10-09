# frozen_string_literal: true

# Stand-in for Jekyll::Drops::PluginCredentialExample::FormattedExample whose
# format template renders a nested component block, so the spec can assert the
# heading level the component assigns to blocks inside format sections.
class NestedBlockFormattedExample < ::Liquid::Drop
  def initialize(format:, presenter:, template_file:)
    super()
    @format = format
    @presenter = presenter
    @template_file = template_file
  end

  attr_reader :format, :presenter, :template_file
end

RSpec.describe 'components/plugin_credential_example.md' do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])

    fixture_includes_dir = File.expand_path('../../../fixtures/includes', __dir__)
    original_paths = JekyllSite.instance.includes_load_paths
    allow(JekyllSite.instance).to receive(:includes_load_paths).and_return([fixture_includes_dir] + original_paths)

    allow(credential_example).to receive(:formatted_examples).and_return([nested_block_formatted_example])
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  let(:credential_example) do
    Jekyll::Drops::PluginCredentialExample.new(
      plugin_name: 'Key Auth',
      example_formats: %w[deck],
      definition: YAML.load_file('app/_data/plugins/credentials/key-auth.yml')
    )
  end

  let(:template) do
    <<~'LIQUID'
      {% include components/plugin_credential_example.md credential_example=credential_example %}
    LIQUID
  end

  let(:nested_block_formatted_example) do
    NestedBlockFormattedExample.new(format: 'deck', presenter: nil, template_file: 'nested_block_details.md')
  end

  let(:rendered) do
    render_liquid(template, page: { 'output_format' => 'markdown' },
                            locals: { 'credential_example' => credential_example })
  end

  it 'renders a nested block heading one level below the credential format heading' do
    expect(rendered.scan(/^\#{1,6} .+$/)).to eq(
      [
        '### Create a Consumer and credential',
        '#### decK',
        '##### **Prerequisite:** Configure your Personal Access Token'
      ]
    )
  end
end
