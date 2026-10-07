# frozen_string_literal: true

RSpec.describe 'prereqs/kubernetes/gateway-api.md' do
  let(:output_format) { 'html' }
  let(:page) do
    {
      'output_format' => output_format,
      'path' => 'test.md',
      'products' => [product],
      'works_on' => %w[konnect on-prem]
    }
  end

  subject(:rendered) { render_liquid(template, page:, locals: { 'config' => config }) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  context 'an operator page' do
    let(:product) { 'operator' }
    let(:config) { { 'gateway_api' => true } }
    let(:template) do
      <<~'LIQUID'
        {% assign product = 'operator' %}
        {% include prereqs/kubernetes/gateway-api.md config=config %}
      LIQUID
    end

    it 'does not render the Gateway API CRD install command' do
      expect(html).to have_no_css('.custom-code-block', text: 'standard-install.yaml')
    end

    it 'renders the Gateway and GatewayClass creation as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', text: 'GatewayClass')
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]',
                               text: 'controllerName: konghq.com/gateway-operator')
    end

    it 'marks exactly one prerequisite fence' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', count: 1)
    end

    it 'says the Helm chart installs the Gateway API CRDs' do
      expect(rendered).to include('Helm chart installs the Gateway API CRDs')
    end
  end

  context 'a KIC page' do
    let(:product) { 'kic' }
    let(:config) { { 'gateway_api' => true } }
    let(:template) do
      <<~'LIQUID'
        {% assign product = 'kic' %}
        {% include prereqs/kubernetes/gateway-api.md config=config %}
      LIQUID
    end

    it 'renders the Gateway API CRD install command as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', text: 'standard-install.yaml')
    end

    it 'renders the Gateway and GatewayClass creation as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', text: 'GatewayClass')
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]',
                               text: 'controllerName: konghq.com/kic-gateway-controller')
    end

    it 'marks exactly two prerequisite fences' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', count: 2)
    end
  end

  context 'a KIC page with the experimental channel' do
    let(:product) { 'kic' }
    let(:config) { { 'gateway_api' => 'experimental' } }
    let(:template) do
      <<~'LIQUID'
        {% assign product = 'kic' %}
        {% include prereqs/kubernetes/gateway-api.md config=config %}
      LIQUID
    end

    it 'renders the experimental CRD install command as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', text: 'experimental-install.yaml')
    end

    it 'marks exactly two prerequisite fences' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', count: 2)
    end
  end
end
