# frozen_string_literal: true

require 'kramdown'

RSpec.describe 'syntax_highlighting.html' do
  let(:highlighter) { instance_double(CodeHighlighter, highlight: 'HIGHLIGHTED') }

  before do
    JekyllSite.instance.data['entity_examples'] =
      { 'config' => YAML.load_file(File.join(PROJECT_ROOT, 'app/_data/entity_examples/config.yml'), aliases: true) }
    allow(Jekyll).to receive(:sites).and_return([JekyllSite.instance])
    allow(CodeHighlighter).to receive(:new).and_return(highlighter)
  end

  after { JekyllSite.instance.data.delete('entity_examples') }

  def render(markdown)
    Capybara::Node::Simple.new(Kramdown::Document.new(markdown, input: 'GFM').to_html)
  end

  def header_labels(html)
    html.all('.custom-code-block__header .justify-self-start > div').map(&:text)
  end

  context 'with both data-file and data-tool' do
    let(:html) do
      render(<<~MD)
        ```yaml
        _format_version: "3.0"
        ```
        {: data-file="kong.yaml" data-tool="deck" }
      MD
    end

    it 'carries data-tool and data-file on the outer code block' do
      expect(html).to have_css('div.custom-code-block[data-tool="deck"][data-file="kong.yaml"]')
    end

    it 'renders a header' do
      expect(html).to have_css('.custom-code-block__header')
    end

    it "renders the tool's config label before the filename" do
      expect(header_labels(html)).to eq(['decK', 'kong.yaml'])
    end

    it 'renders the tool label with the muted style and the filename with the primary style' do
      expect(html).to have_css('.custom-code-block__header .text-primary', text: 'decK')
      expect(html).to have_css('.custom-code-block__header .text-primary', text: 'kong.yaml')
    end
  end

  context 'with a kongctl data-tool' do
    let(:html) do
      render(<<~MD)
        ```yaml
        ref: my-service
        ```
        {: data-file="service.yaml" data-tool="kongctl" }
      MD
    end

    it "renders kongctl's config label before the filename" do
      expect(header_labels(html)).to eq(['kongctl', 'service.yaml'])
    end
  end

  context 'with data-file but no data-tool' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: data-file="model.yaml" }
      MD
    end

    it 'renders a header with only the filename' do
      expect(header_labels(html)).to eq(['model.yaml'])
    end

    it 'does not render a tool label' do
      expect(html).not_to have_css('.text-secondary')
    end

    it 'does not carry a data-tool attribute on the outer code block' do
      expect(html).to have_css('div.custom-code-block[data-file="model.yaml"]')
      expect(html).not_to have_css('div.custom-code-block[data-tool]')
    end
  end

  context 'with neither data-file nor data-tool' do
    let(:html) do
      render(<<~MD)
        ```bash
        echo hello
        ```
      MD
    end

    it 'renders the code block without a header' do
      expect(html).to have_css('div.custom-code-block')
      expect(html).not_to have_css('.custom-code-block__header')
    end
  end

  context 'with copy disabled via the no-copy-code class' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: class="no-copy-code" data-file="model.yaml" }
      MD
    end

    it 'renders the header without a copy button' do
      expect(html).to have_css('.custom-code-block__header')
      expect(html).not_to have_css('.custom-code-block__header clipboard-copy')
    end
  end

  context 'with copy enabled (default)' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: data-file="model.yaml" }
      MD
    end

    it 'renders a copy button in the header' do
      expect(html).to have_css('.custom-code-block__header clipboard-copy')
    end
  end

  context 'with a collapsible code block' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: class="collapsible" }
      MD
    end

    it 'renders the footer "Toggle code" button' do
      expect(html).to have_css('button.collapsible-toggle--footer', text: 'Toggle code')
    end
  end

  context 'with a non-collapsible code block' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
      MD
    end

    it 'renders no footer toggle button' do
      expect(html).not_to have_css('button.collapsible-toggle--footer')
    end
  end

  context 'with no header (no data-file/data-tool) and collapsible + copy enabled' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: class="collapsible" }
      MD
    end

    it 'renders no header, since there is no data-file/data-tool to show' do
      expect(html).not_to have_css('.custom-code-block__header')
      expect(html).to have_css('div.custom-code-block')
      expect(html).not_to have_css('div.custom-code-block[data-file]')
      expect(html).not_to have_css('div.custom-code-block[data-tool]')
    end

    it 'falls back to inline floating actions instead of a header' do
      expect(html).to have_css('button.collapsible-toggle')
      expect(html).to have_css('clipboard-copy')
    end

    it 'pads the snippet container to make room for the floating actions' do
      expect(html).to have_css('[data-code-snippet].pr-11')
    end
  end

  context 'with no header and copy disabled and not collapsible' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: class="no-copy-code" }
      MD
    end

    it 'renders no data-file/data-tool attributes and no header' do
      expect(html).not_to have_css('.custom-code-block__header')
      expect(html).not_to have_css('div.custom-code-block[data-file]')
      expect(html).not_to have_css('div.custom-code-block[data-tool]')
    end

    it 'renders no floating actions and no extra padding' do
      expect(html).not_to have_css('button.collapsible-toggle')
      expect(html).not_to have_css('clipboard-copy')
      expect(html).not_to have_css('[data-code-snippet].pr-11')
    end
  end

  context 'with extra classes on the fence' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: class="my-custom-class" data-file="model.yaml" }
      MD
    end

    it 'passes the classes through to the outer code block' do
      expect(html).to have_css('div.custom-code-block.my-custom-class')
    end
  end

  context 'with an arbitrary data-* attribute' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: data-test-step="block" }
      MD
    end

    it 'passes it through to the outer code block' do
      expect(html).to have_css('div.custom-code-block[data-test-step="block"]')
    end
  end

  context 'when no language is given on the fence' do
    let(:html) do
      render(<<~MD)
        ```
        foo: bar
        ```
        {: data-file="model.yaml" }
      MD
    end

    it "falls back to the 'text' language for highlighting" do
      html
      expect(highlighter).to have_received(:highlight).with(anything, 'text', anything)
    end
  end

  context 'when a language is given on the fence' do
    let(:html) do
      render(<<~MD)
        ```yaml
        foo: bar
        ```
        {: data-file="model.yaml" }
      MD
    end

    it 'passes that language through to highlighting' do
      html
      expect(highlighter).to have_received(:highlight).with(anything, 'yaml', anything)
    end
  end
end
