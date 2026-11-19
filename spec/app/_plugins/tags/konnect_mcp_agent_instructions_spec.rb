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
      'content_type' => 'how_to',
      'output_format' => 'html',
      'works_on' => %w[konnect],
      'products' => %w[gateway]
    }
  end

  before do
    allow(Jekyll::ComponentTemplates).to receive(:fetch).and_call_original
  end

  subject(:rendered) { render_liquid(template, page:) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  def wrapper
    html.find('.agent-instructions', visible: :all)
  end

  it 'dispatches to the html template' do
    rendered

    expect(Jekyll::ComponentTemplates).to have_received(:fetch).with('konnect_mcp_agent_instructions', 'html')
  end

  context 'a Konnect gateway page' do
    it 'renders the hidden wrapper with the crawler exclusion class' do
      expect(html).to have_css('.agent-instructions[hidden]', visible: :all)
    end

    it 'gives every heading the no_toc class' do
      headings = wrapper.all('h2, h3, h4, h5, h6', visible: :all)

      expect(headings).not_to be_empty
      expect(headings.map { |heading| heading[:class].split }).to all(include('no_toc'))
    end

    it 'selects the Gateway subsection' do
      expect(wrapper).to have_text('kong/kong-gateway')
    end
  end

  context 'a page that is not Konnect' do
    let(:page) { super().merge('works_on' => %w[on-prem]) }

    it 'renders nothing and does not fetch a template' do
      expect(rendered.strip).to be_empty
      expect(Jekyll::ComponentTemplates).not_to have_received(:fetch)
    end
  end

  context 'a Konnect page that is not a how-to' do
    let(:page) { super().merge('content_type' => 'plugin') }

    it 'renders nothing, because the markdown layout serves every page type' do
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

    it 'renders markdown headings and no HTML wrapper' do
      expect(rendered).to match(/^## .+$/m)
      expect(rendered).not_to include('agent-instructions')
    end

    it 'selects the same per-product subsection as the html form' do
      expect(rendered).to include('kong/kong-gateway')
    end
  end

  context 'a page whose first product is identity with AI Gateway as a second product' do
    let(:page) { super().merge('products' => %w[identity ai-gateway]) }

    it 'selects the AI Gateway subsection' do
      expect(wrapper).to have_text('kong/kong-ai-gateway')
      expect(wrapper).to have_no_text('kong/kong-gateway')
    end
  end

  context 'a page whose first product is gateway with AI Gateway as a second product' do
    let(:page) { super().merge('products' => %w[gateway ai-gateway]) }

    it 'selects the Gateway subsection' do
      expect(wrapper).to have_text('kong/kong-gateway')
      expect(wrapper).to have_no_text('kong/kong-ai-gateway')
    end
  end

  context 'a page whose only product is event gateway' do
    let(:page) { super().merge('products' => %w[event-gateway]) }

    it 'selects the Event Gateway subsection, not the AI Gateway one' do
      expect(wrapper).to have_text('kong/kong-event-gateway')
      expect(wrapper).to have_no_text('kong/kong-ai-gateway')
      expect(wrapper).to have_text('event gateway nodes')
    end
  end

  context 'a page whose only product is identity' do
    let(:page) { super().merge('products' => %w[identity]) }

    it 'renders the shared introduction and omits the data plane provisioning section' do
      expect(wrapper).to have_text('Instructions for Agents')
      expect(wrapper).to have_no_text('Data plane provisioning')
    end
  end
end
