# frozen_string_literal: true

RSpec.describe Jekyll::Validation do
  let(:how_tos_config) do
    {
      'container' => {
        'konnect' => '$KONNECT_DP_CONTAINER',
        'on_prem' => 'kong-quickstart-gateway'
      },
      'validations' => []
    }
  end
  let(:site_data) { { 'how-tos' => { 'config' => how_tos_config } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end
  let(:template) do
    <<~LIQUID
      {% validation vault-secret %}
      secret: '{vault://hashicorp-vault/customer/acme/name}'
      value: 'ACME Inc.'
      {% endvalidation %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    context 'works_on: konnect' do
      let(:works_on) { %w[konnect] }

      it 'renders a konnect content div with the markdown attribute' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][markdown="1"]')
      end

      it 'renders a data-test-step attribute' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][data-test-step]')
      end

      it 'does not render an on-prem content div' do
        expect(html).not_to have_css('div[data-deployment-topology="on-prem"]')
      end

      it 'uses the konnect container' do
        expect(rendered).to include('docker exec $KONNECT_DP_CONTAINER')
      end
    end

    context 'works_on: on-prem' do
      let(:works_on) { %w[on-prem] }

      it 'renders an on-prem content div with the markdown attribute' do
        expect(html).to have_css('div[data-deployment-topology="on-prem"][markdown="1"]')
      end

      it 'renders a data-test-step attribute' do
        expect(html).to have_css('div[data-deployment-topology="on-prem"][data-test-step]')
      end

      it 'does not render a konnect content div' do
        expect(html).not_to have_css('div[data-deployment-topology="konnect"]')
      end

      it 'uses the on-prem container' do
        expect(rendered).to include('docker exec kong-quickstart-gateway')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both content divs with the markdown attribute' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][markdown="1"]')
        expect(html).to have_css('div[data-deployment-topology="on-prem"][markdown="1"]')
      end

      it 'renders a data-test-step attribute on both content divs' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][data-test-step]')
        expect(html).to have_css('div[data-deployment-topology="on-prem"][data-test-step]')
      end
    end

    context 'with a command override' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% validation vault-secret %}
          secret: '{vault://aws-vault/my-aws-secret/token}'
          value: 'secret'
          command: kubectl exec -n kong -it deployment/kong-gateway -c proxy --
          {% endvalidation %}
        LIQUID
      end

      it 'uses the given command instead of the konnect container' do
        expect(rendered).to include('kubectl exec -n kong -it deployment/kong-gateway -c proxy -- kong vault get')
        expect(rendered).not_to include('docker exec')
      end
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
    end

    context 'works_on: konnect' do
      let(:works_on) { %w[konnect] }

      it 'renders the konnect snippet' do
        expect(rendered).to include('docker exec $KONNECT_DP_CONTAINER')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### Konnect deployments')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both snippets' do
        expect(rendered).to include('docker exec $KONNECT_DP_CONTAINER')
        expect(rendered).to include('docker exec kong-quickstart-gateway')
      end

      it 'renders a deployment topology heading for each, konnect before on-prem' do
        expect(rendered.index('### Konnect deployments')).to be < rendered.index('### On-prem deployments')
      end
    end
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'missing secret' do
      let(:template) do
        <<~LIQUID
          {% validation vault-secret %}
          value: 'ACME Inc.'
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `secret` in {% validation vault-secret %}.')
      end
    end

    context 'missing value' do
      let(:template) do
        <<~LIQUID
          {% validation vault-secret %}
          secret: '{vault://hashicorp-vault/customer/acme/name}'
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `value` in {% validation vault-secret %}.')
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/vault-secret/index.html') }

    it 'renders the snippet include for konnect' do
      expect(template_source).to include('{% include how-tos/validations/vault-secret/snippet.md container=config.container.konnect')
    end

    it 'renders the snippet include for on-prem' do
      expect(template_source).to include('{% include how-tos/validations/vault-secret/snippet.md container=config.container.on_prem')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/vault-secret/index.md') }

      it 'renders the snippet include for konnect' do
        expect(template_source).to include('{% include how-tos/validations/vault-secret/snippet.md container=config.container.konnect')
      end

      it 'renders the snippet include for on-prem' do
        expect(template_source).to include('{% include how-tos/validations/vault-secret/snippet.md container=config.container.on_prem')
      end
    end
  end
end
