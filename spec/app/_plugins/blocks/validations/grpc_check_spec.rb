# frozen_string_literal: true

RSpec.describe Jekyll::Validation do
  let(:how_tos_config) do
    {
      'url_origin' => {
        'konnect' => 'https://konnect.example.com',
        'on_prem' => 'https://on-prem.example.com'
      },
      'validations' => []
    }
  end
  let(:site_data) { { 'how-tos' => { 'config' => how_tos_config } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['kic'], 'works_on' => works_on }
  end
  let(:template) do
    <<~LIQUID
      {% validation grpc-check %}
      method: hello.HelloService.SayHello
      port: 443
      {% endvalidation %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    include_examples 'a dual-topology content div'

    context 'works_on: konnect' do
      let(:works_on) { %w[konnect] }

      it 'renders the flex layout classes' do
        expect(html).to have_css('div.flex.flex-col.gap-3[data-deployment-topology="konnect"]')
      end

      it 'resolves the konnect url from how_tos_config, with no path suffix' do
        expect(rendered).to include('https://konnect.example.com:443')
      end
    end

    context 'overriding konnect_url/on_prem_url' do
      let(:works_on) { %w[konnect on-prem] }
      let(:template) do
        <<~LIQUID
          {% validation grpc-check %}
          method: hello.HelloService.SayHello
          port: 443
          konnect_url: $PROXY_IP
          on_prem_url: $PROXY_IP
          {% endvalidation %}
        LIQUID
      end

      it 'uses the overridden host for both topologies, ignoring url_origin' do
        expect(rendered).to include('$PROXY_IP:443')
        expect(rendered).not_to include('https://konnect.example.com')
        expect(rendered).not_to include('https://on-prem.example.com')
      end
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => ['kic'], 'works_on' => works_on }
    end

    context 'works_on: konnect' do
      let(:works_on) { %w[konnect] }

      it 'renders the konnect snippet' do
        expect(rendered).to include('https://konnect.example.com:443')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### Konnect deployments')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both snippets' do
        expect(rendered).to include('https://konnect.example.com:443')
        expect(rendered).to include('https://on-prem.example.com:443')
      end

      it 'renders a deployment topology heading for each, konnect before on-prem' do
        expect(rendered.index('### Konnect deployments')).to be < rendered.index('### On-prem deployments')
      end
    end
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'missing method' do
      let(:template) do
        <<~LIQUID
          {% validation grpc-check %}
          port: 443
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `method` in {% validation grpc-check %}.')
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/grpc-check/index.html') }

    it 'renders the snippet include for konnect' do
      expect(template_source).to include('{% include how-tos/validations/grpc-check/snippet.md url=config.konnect_url')
    end

    it 'renders the snippet include for on-prem' do
      expect(template_source).to include('{% include how-tos/validations/grpc-check/snippet.md url=config.on_prem_url')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/grpc-check/index.md') }

      it 'renders the snippet include for konnect' do
        expect(template_source).to include('{% include how-tos/validations/grpc-check/snippet.md url=config.konnect_url')
      end

      it 'renders the snippet include for on-prem' do
        expect(template_source).to include('{% include how-tos/validations/grpc-check/snippet.md url=config.on_prem_url')
      end
    end
  end
end
