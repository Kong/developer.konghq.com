# frozen_string_literal: true

require 'kramdown'

RSpec.describe 'plugins/example.md' do
  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
    stub_const('Jekyll::Drops::Plugins::Schema::SCHEMAS_BASE', fixture_schemas_base)
  end

  after do
    JekyllSite.instance.data.delete('entity_examples')
    Jekyll::Drops::Plugins::Schema::FILE_INDEX
      .reject { |dir, _| dir.start_with?(fixture_schemas_base) }
      .each_key { |dir| Jekyll::Drops::Plugins::Schema::FILE_INDEX.delete(dir) }
  end

  let(:fixture_schemas_base) { File.join(JekyllSite.instance.source, '_schemas/gateway/plugins') }

  let(:plugin) do
    Jekyll::PluginPages::Plugin.new(
      folder: File.join(JekyllSite.instance.source, '_kong_plugins', 'fixture-auth'),
      slug: 'fixture-auth'
    )
  end

  def render_example_page(example_slug)
    file = plugin.example_files.detect { |f| File.basename(f, File.extname(f)) == example_slug }
    page = Jekyll::PluginPages::Pages::Example.new(plugin:, file:)

    rendered = render_liquid(page.content, page: page.data)
    Capybara::Node::Simple.new(Kramdown::Document.new(rendered, input: 'GFM').to_html)
  end

  def heading_ids(html)
    html.all('h2').map { |heading| heading[:id] }
  end

  shared_examples 'a page with an ordered credential section' do
    it 'renders the credential section after the example title and directly before the plugin configuration section' do
      ids = heading_ids(html)

      expect(ids.index('create-a-consumer-and-credential')).to be > ids.index(title_id)
      expect(ids.index('create-a-consumer-and-credential')).to be < ids.index('set-up-the-plugin')
    end

    it 'renders the credential section heading with its own anchor' do
      expect(html).to have_css('h2#create-a-consumer-and-credential a[href="#create-a-consumer-and-credential"]')
    end
  end

  context 'when the example has no Prerequisites and Environment variables sections' do
    let(:html) { render_example_page('enable-fixture-auth') }
    let(:title_id) { 'enable-fixture-auth' }

    include_examples 'a page with an ordered credential section'
  end

  context 'when the example has Prerequisites and Environment variables sections' do
    let(:html) { render_example_page('with-prerequisites') }
    let(:title_id) { 'enable-fixture-auth-with-prerequisites' }

    include_examples 'a page with an ordered credential section'

    it 'renders the credential section after the Prerequisites and Environment variables sections' do
      ids = heading_ids(html)

      expect(ids.index('create-a-consumer-and-credential')).to be > ids.index('prerequisites')
      expect(ids.index('create-a-consumer-and-credential')).to be > ids.index('environment-variables')
    end
  end

  context 'when the example opts out of the credential section' do
    let(:html) { render_example_page('opted-out') }

    it 'renders no credential section' do
      expect(heading_ids(html)).not_to include('create-a-consumer-and-credential')
      expect(heading_ids(html)).to include('set-up-the-plugin')
    end
  end
end
