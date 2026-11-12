# frozen_string_literal: true

require 'kramdown'

RSpec.describe 'plugins/example.md' do
  before do
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
    stub_const('Jekyll::Drops::Plugins::Schema::SCHEMAS_BASE', fixture_schemas_base)
  end

  after do
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

  def render_example_page(example_slug, output_format: 'html')
    file = plugin.example_files.detect { |f| File.basename(f, File.extname(f)) == example_slug }
    page = Jekyll::PluginPages::Pages::Example.new(plugin:, file:)

    rendered = render_liquid(page.content, page: page.data.merge('output_format' => output_format))
    return rendered if output_format == 'markdown'

    Capybara::Node::Simple.new(Kramdown::Document.new(rendered, input: 'GFM').to_html)
  end

  def heading_ids(html)
    html.all('h2,h3').map { |heading| heading[:id] }
  end

  def markdown_headings(markdown)
    markdown.scan(/^\#{1,6} .+$/)
  end

  shared_examples 'a page with an ordered credential section' do
    it 'renders the credential section after the example title and directly before the plugin configuration section' do
      ids = heading_ids(html)

      expect(ids.index('create-a-consumer-and-credential')).to be > ids.index(title_id)
      expect(ids.index('create-a-consumer-and-credential')).to be < ids.index('set-up-the-plugin')
    end

    it 'renders the credential section heading with its own anchor' do
      expect(html).to have_css('h3#create-a-consumer-and-credential a[href="#create-a-consumer-and-credential"]')
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

  context 'when the configuration section renders both selectors' do
    let(:html) { render_example_page('with-prerequisites') }

    it 'labels every panel with an element that exists on the page' do
      expect(dangling_aria_labelledby_ids(html)).to eq([])
    end

    it 'labels each panel with the selector of its own section' do
      config_section = html.all('.entity-example').last
      target_panel = config_section.find('.entity-example-target-panel[data-target="global"]')

      expect(target_panel[:'aria-labelledby']).to eq(config_section.find('select.select-target')[:id])
      expect(target_panel.find('.entity-example-format-panel[data-format="terraform"]')[:'aria-labelledby'])
        .to eq(config_section.find('select.select-format')[:id])
    end
  end

  context 'when the configuration section renders a single target' do
    let(:html) { render_example_page('enable-fixture-auth-route') }

    it 'labels every panel with an element that exists on the page' do
      expect(dangling_aria_labelledby_ids(html)).to eq([])
    end

    it 'labels the target panel with the section heading when there is no scope selector' do
      config_section = html.all('.entity-example').last

      expect(config_section).not_to have_css('select.select-target')
      expect(config_section.find('.entity-example-target-panel')[:'aria-labelledby'])
        .to eq('set-up-the-plugin')
    end
  end

  context 'when the page renders in markdown output' do
    let(:rendered) { render_example_page('enable-fixture-auth-route', output_format: 'markdown') }

    it 'renders the target heading at h4 and the Terraform and KIC format headings at h5' do
      expect(markdown_headings(rendered)).to include('#### Route', '##### Terraform', '##### KIC')
    end

    it 'renders the Terraform prerequisite details heading at h6' do
      expect(markdown_headings(rendered)).to include('###### **Prerequisite:** Configure your Personal Access Token')
    end

    it 'renders the KIC Gateway API and Ingress tab headings at h6' do
      expect(markdown_headings(rendered)).to include('###### Gateway API', '###### Ingress')
    end
  end

  context 'when a page with a credential section renders in markdown output' do
    let(:rendered) { render_example_page('with-prerequisites', output_format: 'markdown') }

    it 'renders the full heading hierarchy in order' do
      expect(markdown_headings(rendered)).to eq(
        [
          '## Enable Fixture Auth with prerequisites',
          '### Prerequisites',
          '### Environment variables',
          '### Create a Consumer and credential',
          '#### decK',
          '#### Admin API',
          '#### Konnect API',
          '#### KIC',
          '#### Terraform',
          '### Set up the plugin',
          '#### Global',
          '##### decK',
          '##### Admin API',
          '##### Konnect API',
          '##### KIC',
          '##### Terraform',
          '###### **Prerequisite:** Configure your Personal Access Token',
          '#### Route',
          '##### decK',
          '##### Admin API',
          '##### Konnect API',
          '##### KIC',
          '###### Gateway API',
          '###### Ingress',
          '##### Terraform',
          '###### **Prerequisite:** Configure your Personal Access Token'
        ]
      )
    end
  end
end
