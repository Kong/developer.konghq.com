# frozen_string_literal: true

RSpec.describe Jekyll::RenderMermaid do
  subject(:rendered) { render_liquid(template, page: page) }

  let(:page) { { 'output_format' => 'html', 'path' => 'gateway/test.md' } }
  let(:template) do
    <<~LIQUID
      {% mermaid %}
      flowchart LR
        A[Client] --> B[Gateway]
      {% endmermaid %}
    LIQUID
  end

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    it 'hands the diagram source to the browser to mount' do
      expect(html).to have_css('pre.mermaid')
      expect(html.find('pre.mermaid').text).to include('flowchart LR')
      expect(html.find('pre.mermaid').text).to include('A[Client] --> B[Gateway]')
    end

    it 'does not render the diagram itself' do
      expect(rendered).not_to include('<svg')
    end

    context 'when the source contains a raw angle bracket' do
      let(:template) do
        <<~LIQUID
          {% mermaid %}
          sequenceDiagram
            User->>Konnect: login (Bearer <apiKey>)
          {% endmermaid %}
        LIQUID
      end

      it 'escapes it so the browser cannot read it as a tag' do
        expect(rendered).to include('&lt;apiKey&gt;')
        expect(html.find('pre.mermaid').text).to include('login (Bearer <apiKey>)')
      end
    end

    context 'when the source contains an escaped angle bracket' do
      let(:template) do
        <<~LIQUID
          {% mermaid %}
          sequenceDiagram
            User->>Konnect: login (&lt;custom_path&gt;)
          {% endmermaid %}
        LIQUID
      end

      it 'leaves it escaped exactly once' do
        expect(rendered).to include('&lt;custom_path&gt;')
        expect(rendered).not_to include('&amp;lt;custom_path&gt;')
        expect(html.find('pre.mermaid').text).to include('login (<custom_path>)')
      end
    end

    context 'when the source contains a doubly escaped entity' do
      let(:template) do
        <<~LIQUID
          {% mermaid %}
          flowchart LR
            KIC1[fa:fa-gateway KIC &amp;lpar;Active&amp;rpar;]
          {% endmermaid %}
        LIQUID
      end

      it 'leaves the entity for Pele to decode' do
        expect(html.find('pre.mermaid').text).to include('&lpar;Active&rpar;')
      end
    end
  end

  describe 'markdown output' do
    let(:page) { { 'output_format' => 'markdown', 'path' => 'gateway/test.md' } }

    it 'emits a mermaid fence instead of the mounting markup' do
      expect(rendered).to start_with(<<~MARKDOWN)
        ```mermaid
        flowchart LR
          A[Client] --> B[Gateway]
        ```
      MARKDOWN
      expect(rendered).not_to include('<pre')
    end

    context 'when the source contains a doubly escaped entity' do
      let(:template) do
        <<~LIQUID
          {% mermaid %}
          flowchart LR
            KIC1[fa:fa-gateway KIC &amp;lpar;Active&amp;rpar;]
          {% endmermaid %}
        LIQUID
      end

      it 'shows the source the renderer actually receives' do
        expect(rendered).to include('[fa:fa-gateway KIC &lpar;Active&rpar;]')
      end
    end
  end
end
