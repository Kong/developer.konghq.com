# frozen_string_literal: true

RSpec.describe 'prereqs/products/operator.md' do
  let(:output_format) { 'html' }
  let(:template) do
    <<~'LIQUID'
      {% include prereqs/products/operator.md %}
    LIQUID
  end
  let(:page) do
    {
      'output_format' => output_format,
      'path' => 'test.md',
      'products' => ['operator'],
      'works_on' => %w[konnect on-prem]
    }
  end

  subject(:rendered) { render_liquid(template, page:) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  context 'the HTML output format' do
    it 'declares the operator test setup in a hidden div' do
      expect(html).to have_css('div.hidden[data-test-setup="operator"]')
    end

    it 'marks the Helm repo fence as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]',
                               text: 'helm repo add kong https://charts.konghq.com')
    end

    it 'marks the on-prem Helm install fence as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]',
                               text: 'helm upgrade --install kong-operator kong/kong-operator')
    end

    it 'marks the on-prem KongLicense fence as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', text: 'KongLicense')
    end

    it 'marks exactly three prerequisite fences' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', count: 3)
    end

    it 'leaves the Konnect Helm install fence unmarked' do
      expect(html).to have_no_css('.custom-code-block[data-test-prereq="block"]',
                                  text: 'ENABLE_CONTROLLER_KONNECT=true')
    end

    it 'renders the on-prem Helm install command without a trailing continuation' do
      install = html.find('.custom-code-block[data-test-prereq="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(install.find('pre').text.strip).not_to end_with('\\')
    end
  end

  context 'a pinned chart version' do
    let(:template) do
      <<~'LIQUID'
        {% include prereqs/products/operator.md chart_version="2.3.0" %}
      LIQUID
    end

    it 'renders the on-prem Helm install command without a trailing continuation' do
      install = html.find('.custom-code-block[data-test-prereq="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(install.find('pre').text.strip).not_to end_with('\\')
    end
  end

  context 'the markdown output format' do
    let(:output_format) { 'markdown' }

    it 'omits the test setup div' do
      expect(rendered).not_to include('data-test-setup')
    end
  end
end
