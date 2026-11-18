# frozen_string_literal: true

RSpec.describe 'konnect_mcp_agent_instructions tag' do
  let(:template) do
    <<~'LIQUID'
      {% konnect_mcp_agent_instructions %}
    LIQUID
  end

  let(:page) do
    {
      'path' => 'test/page.md',
      'output_format' => 'html',
      'works_on' => %w[konnect],
      'products' => %w[gateway]
    }
  end

  # The component templates land in the next commit, so this one stubs the
  # fetch. The gate and the per-format dispatch need only that a template comes
  # back; the rendered shape is asserted once the templates exist.
  before do
    allow(Jekyll::ComponentTemplates).to receive(:fetch).and_return(Liquid::Template.parse(''))
  end

  subject(:rendered) { render_liquid(template, page:) }

  it 'dispatches to the html template' do
    rendered

    expect(Jekyll::ComponentTemplates).to have_received(:fetch).with('konnect_mcp_agent_instructions', 'html')
  end

  context 'a page that is not Konnect' do
    let(:page) { super().merge('works_on' => %w[on-prem]) }

    it 'renders nothing and does not fetch a template' do
      expect(rendered.strip).to be_empty
      expect(Jekyll::ComponentTemplates).not_to have_received(:fetch)
    end
  end

  context 'a Konnect page whose first product is not in the list' do
    let(:page) { super().merge('products' => %w[operator]) }

    it 'renders nothing' do
      expect(rendered.strip).to be_empty
      expect(Jekyll::ComponentTemplates).not_to have_received(:fetch)
    end
  end

  context 'a Konnect page whose first product is not in the list, even though a later product is' do
    let(:page) { super().merge('products' => %w[dev-portal gateway]) }

    it 'renders nothing' do
      expect(rendered.strip).to be_empty
      expect(Jekyll::ComponentTemplates).not_to have_received(:fetch)
    end
  end

  context 'rendered as markdown' do
    let(:page) { super().merge('output_format' => 'markdown') }

    it 'dispatches to the markdown template' do
      rendered

      expect(Jekyll::ComponentTemplates).to have_received(:fetch).with('konnect_mcp_agent_instructions', 'markdown')
    end
  end
end
