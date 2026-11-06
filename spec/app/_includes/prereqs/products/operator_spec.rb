# frozen_string_literal: true

RSpec.describe 'prereqs/products/operator.md' do
  let(:output_format) { 'html' }
  let(:template) do
    <<~LIQUID
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

    it 'marks both Helm install fences as prerequisites' do
      installs = html.all('.custom-code-block[data-test-prereq="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(installs.size).to eq(2)
    end

    it 'marks the on-prem KongLicense fence as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', text: 'KongLicense')
    end

    it 'marks exactly four prerequisite fences' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]', count: 4)
    end

    it 'marks the Konnect Helm install fence as a prerequisite' do
      expect(html).to have_css('.custom-code-block[data-test-prereq="block"]',
                               text: 'ENABLE_CONTROLLER_KONNECT=true')
    end

    it 'renders the install commands without a trailing continuation' do
      html.all('.custom-code-block[data-test-prereq="block"]',
               text: 'helm upgrade --install kong-operator kong/kong-operator').each do |install|
        expect(install.find('pre').text.strip).not_to end_with('\\')
      end
    end

    it 'waits for the operator deployment to become ready in both install prerequisites' do
      installs = html.all('.custom-code-block[data-test-prereq="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(installs.size).to eq(2)
      installs.each do |install|
        expect(install.find('pre').text).to include(
          'kubectl -n kong-system wait --for=condition=Available=true --timeout=300s ' \
          'deployment/kong-operator-kong-operator-controller-manager'
        )
      end
    end
  end

  context 'embedded raw in the page body' do
    let(:template) do
      <<~LIQUID
        {% include prereqs/products/operator.md raw=true v_maj=2 %}
      LIQUID
    end

    # A raw include renders as page-body markdown that Jekyll converts to HTML
    # later in the page pipeline, so these assertions run against the
    # kramdown-converted output rather than the Liquid output.
    def html
      Capybara::Node::Simple.new(Kramdown::Document.new(rendered, input: 'GFM').to_html)
    end

    it 'marks the Helm repo fence as a step' do
      expect(html).to have_css('.custom-code-block[data-test-step="block"]',
                               text: 'helm repo add kong https://charts.konghq.com')
    end

    it 'marks both Helm install fences as steps' do
      installs = html.all('.custom-code-block[data-test-step="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(installs.size).to eq(2)
    end

    it 'waits for the operator deployment to become ready in both install steps' do
      installs = html.all('.custom-code-block[data-test-step="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(installs.size).to eq(2)
      installs.each do |install|
        expect(install.find('pre').text).to include(
          'kubectl -n kong-system wait --for=condition=Available=true --timeout=300s ' \
          'deployment/kong-operator-kong-operator-controller-manager'
        )
      end
    end

    it 'renders the install steps as valid bash' do
      html.all('.custom-code-block[data-test-step="block"]',
               text: 'helm upgrade --install kong-operator kong/kong-operator').each do |install|
        validate_bash_syntax!(install.find('pre').text)
      end
    end

    it 'marks the on-prem KongLicense fence as a step' do
      expect(html).to have_css('.custom-code-block[data-test-step="block"]', text: 'KongLicense')
    end

    it 'marks exactly four step fences' do
      expect(html).to have_css('.custom-code-block[data-test-step="block"]', count: 4)
    end

    it 'marks no fence as a prerequisite' do
      expect(html).to have_no_css('.custom-code-block[data-test-prereq]')
    end
  end

  context 'embedded raw in the page body with the v1 chart' do
    let(:template) do
      <<~LIQUID
        {% include prereqs/products/operator.md raw=true v_maj=1 %}
      LIQUID
    end

    def html
      Capybara::Node::Simple.new(Kramdown::Document.new(rendered, input: 'GFM').to_html)
    end

    it 'marks the on-prem Helm install fence as a step' do
      expect(html).to have_css('.custom-code-block[data-test-step="block"]',
                               text: 'helm upgrade --install kgo kong/gateway-operator')
    end

    it 'marks no fence as a prerequisite' do
      expect(html).to have_no_css('.custom-code-block[data-test-prereq]')
    end
  end

  context 'extra Helm --set values' do
    let(:template) do
      <<~LIQUID
        {% include prereqs/products/operator.md set='global.webhooks.options.certManager.enabled=true' %}
      LIQUID
    end

    it 'renders the on-prem install command with single line continuations' do
      install = html.find('div[data-deployment-topology="on-prem"] .custom-code-block[data-test-prereq="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      expect(install.find('pre').text.strip).to eq(<<~'CMD'.strip)
        helm upgrade --install kong-operator kong/kong-operator -n kong-system \
          --create-namespace \
           --set image.tag= \
          --set global.webhooks.options.certManager.enabled=true
          kubectl -n kong-system wait --for=condition=Available=true --timeout=300s deployment/kong-operator-kong-operator-controller-manager
      CMD
    end
  end

  context 'page-level controller flags, a pinned chart version, and a KEG dataplane install' do
    let(:template) do
      <<~LIQUID
        {% include prereqs/products/operator.md chart_version='2.4.0' keg_install=true set='a=b' %}
      LIQUID
    end
    let(:page) do
      {
        'output_format' => 'html',
        'path' => 'test.md',
        'products' => ['operator'],
        'works_on' => %w[konnect on-prem],
        'prereqs' => { 'operator' => { 'controllers' => %w[AIGATEWAYDATAPLANE] } }
      }
    end

    it 'renders the on-prem install command with single line continuations' do
      install = html.find('div[data-deployment-topology="on-prem"] .custom-code-block[data-test-prereq="block"]',
                          text: 'helm upgrade --install kong-operator kong/kong-operator')
      command = install.find('pre').text
      expect(command).not_to include(' \ \\')
      expect(command.strip).not_to end_with('\\')
      validate_bash_syntax!(command)
    end
  end

  context 'a pinned chart version' do
    let(:template) do
      <<~LIQUID
        {% include prereqs/products/operator.md chart_version="2.3.0" %}
      LIQUID
    end

    it 'renders the on-prem Helm install command without a trailing continuation' do
      install = html.find('div[data-deployment-topology="on-prem"] .custom-code-block[data-test-prereq="block"]',
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
