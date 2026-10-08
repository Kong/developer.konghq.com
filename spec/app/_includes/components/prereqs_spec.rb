# frozen_string_literal: true

RSpec.describe 'components/prereqs.html' do
  let(:template) do
    <<~'LIQUID'
      {% include components/prereqs.html %}
    LIQUID
  end
  let(:page) do
    {
      'output_format' => 'html',
      'path' => 'test.md',
      'products' => ['operator'],
      'works_on' => %w[konnect on-prem]
    }
  end
  let(:locals) { { 'prereqs' => { 'skip_product' => true } } }

  subject(:rendered) { render_liquid(template, page:, locals:) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  context 'an operator how-to that skips the product include' do
    it 'still declares the operator test setup in a hidden div per works_on platform' do
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="on-prem"][data-test-setup="operator"]'
      )
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
    end

    it 'renders no visible prereq content for the operator' do
      expect(html).to have_css('.prerequisites')
      expect(html).to have_no_css('.prerequisites .accordion-item')
    end
  end

  context 'an operator how-to that skips the product include and only works on konnect' do
    let(:page) do
      {
        'output_format' => 'html',
        'path' => 'test.md',
        'products' => ['operator'],
        'works_on' => ['konnect']
      }
    end

    it 'declares only the konnect operator marker' do
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
      expect(html).to have_no_css('.prerequisites [data-deployment-topology="on-prem"]')
    end
  end

  context 'an operator how-to that needs only konnect auth' do
    let(:page_data) do
      {
        'prereqs' => {},
        'tools' => [],
        'products' => ['operator'],
        'works_on' => ['konnect'],
        'output_format' => 'html'
      }
    end
    let(:drop_page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
    let(:site) { instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source') }
    let(:locals) { { 'prereqs' => Jekyll::Drops::Prereqs.new(page: drop_page, site: site) } }

    it 'declares the operator test setup on the konnect auth prereq' do
      expect(html).to have_css(
        '.prerequisites > [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
    end
  end

  context 'a non-operator how-to that needs only konnect auth' do
    let(:page) do
      {
        'output_format' => 'html',
        'path' => 'test.md',
        'products' => ['mesh'],
        'works_on' => ['konnect']
      }
    end
    let(:page_data) do
      {
        'prereqs' => {},
        'tools' => [],
        'products' => ['mesh'],
        'works_on' => ['konnect'],
        'output_format' => 'html'
      }
    end
    let(:drop_page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
    let(:site) { instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source') }
    let(:locals) { { 'prereqs' => Jekyll::Drops::Prereqs.new(page: drop_page, site: site) } }

    it 'keeps the konnect test setup value' do
      expect(html).to have_css(
        '.prerequisites > [data-deployment-topology="konnect"][data-test-setup="konnect"]'
      )
    end
  end
end

RSpec.describe 'components/prereqs.md' do
  let(:page_data) do
    {
      'output_format' => 'markdown',
      'prereqs' => { 'kubernetes' => { 'gateway_api' => true } },
      'tools' => [],
      'products' => ['operator'],
      'works_on' => %w[konnect on-prem]
    }
  end
  let(:drop_page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
  let(:site) { instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source') }
  let(:prereqs_drop) { Jekyll::Drops::Prereqs.new(page: drop_page, site: site) }
  let(:template) do
    <<~'LIQUID'
      {% include components/prereqs.md %}
    LIQUID
  end
  let(:locals) { { 'prereqs' => prereqs_drop } }

  subject(:rendered) { render_liquid(template, page: page_data, locals:) }

  context 'an operator page with a Gateway API prerequisite' do
    it 'renders the operator install before the Gateway API prerequisite' do
      operator_install = rendered.index('helm upgrade --install kong-operator kong/kong-operator')
      gateway_api = rendered.index('controllerName: konghq.com/gateway-operator')

      expect(operator_install).to be_truthy
      expect(gateway_api).to be_truthy
      expect(operator_install).to be < gateway_api
    end

    it 'renders the Gateway API prerequisite once' do
      expect(rendered.scan('Helm chart installs the Gateway API CRDs').size).to eq(1)
    end

    it 'does not render the standalone CRD install command' do
      expect(rendered).not_to include('standard-install.yaml')
    end

    it 'keeps the late block boundary within the existing blank-line pattern' do
      expect(rendered.scan(/\n{8,}/)).to be_empty
    end
  end
end

RSpec.describe 'prereqs component output parity' do
  def render_component(format, page_data)
    render_page_data = page_data.merge('output_format' => format)
    drop_page = instance_double(Jekyll::Page, data: render_page_data, url: '/test/')
    site = instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source')
    drop = Jekyll::Drops::Prereqs.new(page: drop_page, site: site)
    extension = format == 'markdown' ? 'md' : format
    template = "{% include components/prereqs.#{extension} %}"
    rendered = render_liquid(template, page: render_page_data, locals: { 'prereqs' => drop })
    return Capybara::Node::Simple.new(rendered).find('.prerequisites').text if format == 'html'

    rendered
  end

  def expect_sentinels_in_order(output, *sentinels)
    positions = sentinels.map { |sentinel| output.index(sentinel) }
    sentinels.zip(positions).each do |sentinel, position|
      expect(position).to be_truthy, "expected the output to contain #{sentinel.inspect}"
    end
    positions.each_cons(2) { |earlier, later| expect(earlier).to be < later }
  end

  context 'an operator page with a Gateway API prerequisite' do
    let(:page_data) do
      {
        'prereqs' => { 'kubernetes' => { 'gateway_api' => true } },
        'tools' => [],
        'products' => ['operator'],
        'works_on' => %w[konnect on-prem]
      }
    end
    let(:sentinels) do
      [
        'helm repo add kong https://charts.konghq.com',
        'helm upgrade --install kong-operator kong/kong-operator',
        'controllerName: konghq.com/gateway-operator'
      ]
    end

    it 'renders the same prerequisite order in both output formats' do
      expect_sentinels_in_order(render_component('html', page_data), *sentinels)
      expect_sentinels_in_order(render_component('markdown', page_data), *sentinels)
    end

    it 'renders the Gateway API prerequisite once in both output formats' do
      aggregate_failures do
        %w[html markdown].each do |format|
          output = render_component(format, page_data)
          expect(output.scan('Helm chart installs the Gateway API CRDs').size).to eq(1)
        end
      end
    end
  end

  context 'an operator page without a Gateway API prerequisite' do
    let(:page_data) do
      {
        'prereqs' => { 'kubernetes' => {} },
        'tools' => [],
        'products' => ['operator'],
        'works_on' => %w[konnect on-prem]
      }
    end

    it 'renders no Gateway API prerequisite in either output format' do
      aggregate_failures do
        %w[html markdown].each do |format|
          output = render_component(format, page_data)
          expect(output).not_to include('Enable the Gateway API')
          expect(output).not_to include('GatewayClass')
        end
      end
    end
  end

  context 'a KIC page with a Gateway API prerequisite' do
    let(:page_data) do
      {
        'prereqs' => { 'kubernetes' => { 'gateway_api' => true } },
        'tools' => [],
        'products' => ['kic'],
        'works_on' => %w[konnect on-prem]
      }
    end
    let(:sentinels) do
      [
        'standard-install.yaml',
        'controllerName: konghq.com/kic-gateway-controller',
        'helm install kong kong/ingress'
      ]
    end

    it 'renders the Gateway API prerequisite in the early position in both output formats' do
      expect_sentinels_in_order(render_component('html', page_data), *sentinels)
      expect_sentinels_in_order(render_component('markdown', page_data), *sentinels)
    end
  end

  context 'an AI Gateway page with Konnect environment variables' do
    let(:page_data) do
      {
        'prereqs' => { 'konnect' => [{ 'name' => 'MY_TEST_VAR', 'value' => 'test-value' }] },
        'tools' => [],
        'products' => ['ai-gateway'],
        'works_on' => ['konnect']
      }
    end

    it 'renders the Konnect environment variables in both output formats' do
      aggregate_failures do
        %w[html markdown].each do |format|
          output = render_component(format, page_data)
          expect(output).to include('-e MY_TEST_VAR=test-value')
        end
      end
    end
  end
end
