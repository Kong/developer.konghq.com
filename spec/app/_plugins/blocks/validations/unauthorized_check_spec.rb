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
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end
  let(:template) do
    <<~LIQUID
      {% validation unauthorized-check %}
      url: /anything
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

    context 'indent' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% validation unauthorized-check %}
          url: /echo
          konnect_url: $PROXY_IP
          indent: 3
          {% endvalidation %}
        LIQUID
      end

      it 'applies the requested indent exactly once, since index.html does not indent itself' do
        content_line = rendered.lines.find { |l| l.include?('curl -i') }
        expect(content_line).to eq("   curl -i $PROXY_IP/echo \n")
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
        expect(rendered).to include('https://konnect.example.com/anything')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### Konnect deployments')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both snippets' do
        expect(rendered).to include('https://konnect.example.com/anything')
        expect(rendered).to include('https://on-prem.example.com/anything')
      end

      it 'renders a deployment topology heading for each, konnect before on-prem' do
        expect(rendered.index('### Konnect deployments')).to be < rendered.index('### On-prem deployments')
      end
    end

    context 'with a message and status_code' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% validation unauthorized-check %}
          url: /anything
          status_code: 403
          message: 'Forbidden'
          {% endvalidation %}
        LIQUID
      end

      it 'renders the same sentence as html, since message.md is format-agnostic' do
        expect(rendered).to include('This request returns a `403` error with the message `Forbidden`.')
      end
    end
  end

  describe 'the "This request returns..." message (message.md, tested once since it does not ' \
           'depend on output_format)' do
    let(:works_on) { %w[konnect] }

    context 'status_code and message both set' do
      let(:template) do
        <<~LIQUID
          {% validation unauthorized-check %}
          url: /anything
          status_code: 403
          message: 'Forbidden'
          {% endvalidation %}
        LIQUID
      end

      it 'renders the full sentence' do
        expect(rendered).to include('This request returns a `403` error with the message `Forbidden`.')
      end
    end

    context 'status_code only' do
      let(:template) do
        <<~LIQUID
          {% validation unauthorized-check %}
          url: /anything
          status_code: 401
          {% endvalidation %}
        LIQUID
      end

      it 'renders a sentence with only the status code' do
        expect(rendered).to include('This request returns a `401` error.')
        expect(rendered).not_to include('with the message')
      end
    end

    context 'message only' do
      let(:template) do
        <<~LIQUID
          {% validation unauthorized-check %}
          url: /anything
          message: No API key found in request
          {% endvalidation %}
        LIQUID
      end

      it 'renders a sentence with only the message' do
        expect(rendered).to include('This request returns an error with the message `No API key found in request`.')
      end
    end

    context 'neither set' do
      it 'renders no message sentence at all' do
        expect(rendered).not_to include('This request returns')
      end
    end
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'missing url' do
      let(:template) do
        <<~LIQUID
          {% validation unauthorized-check %}
          status_code: 401
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `url` in {% validation unauthorized-check %}.')
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/unauthorized-check/index.html') }

    it 'renders the snippet include for konnect' do
      expect(template_source).to include('{% include how-tos/validations/unauthorized-check/snippet.md url=config.konnect_url')
    end

    it 'renders the snippet include for on-prem' do
      expect(template_source).to include('{% include how-tos/validations/unauthorized-check/snippet.md url=config.on_prem_url')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/unauthorized-check/index.md') }

      it 'renders the snippet include for konnect' do
        expect(template_source).to include('{% include how-tos/validations/unauthorized-check/snippet.md url=config.konnect_url')
      end

      it 'renders the snippet include for on-prem' do
        expect(template_source).to include('{% include how-tos/validations/unauthorized-check/snippet.md url=config.on_prem_url')
      end
    end
  end
end
