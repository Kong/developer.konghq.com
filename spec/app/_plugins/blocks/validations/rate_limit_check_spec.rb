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
      {% validation rate-limit-check %}
      iterations: 6
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

    context 'with a message and status_code' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% validation rate-limit-check %}
          iterations: 6
          url: /anything
          status_code: 429
          message: Too Many Requests
          {% endvalidation %}
        LIQUID
      end

      it 'renders the status code and message outside the content divs' do
        expect(rendered).to include('you should get a `429` response with the message `Too Many Requests`')
      end
    end

    context 'with no message' do
      let(:works_on) { %w[konnect] }

      it 'does not render the status code and message text' do
        expect(rendered).not_to include('you should get a')
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

    context 'works_on: on-prem' do
      let(:works_on) { %w[on-prem] }

      it 'renders the on-prem snippet' do
        expect(rendered).to include('https://on-prem.example.com/anything')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### On-prem deployments')
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
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'missing iterations' do
      let(:template) do
        <<~LIQUID
          {% validation rate-limit-check %}
          url: /anything
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `iterations` in {% validation rate-limit-check %}.')
      end
    end

    context 'grep specified with no output at all' do
      let(:template) do
        <<~LIQUID
          {% validation rate-limit-check %}
          iterations: 6
          url: /anything
          grep: "HTTP"
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'output.expected must be provided if `grep` is specified')
      end
    end

    context 'grep specified with output.explanation but no output.expected' do
      let(:template) do
        <<~LIQUID
          {% validation rate-limit-check %}
          iterations: 6
          url: /anything
          grep: "HTTP"
          output:
            explanation: "some text"
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'output.expected must be provided if `grep` is specified')
      end
    end

    context 'missing url' do
      let(:template) do
        <<~LIQUID
          {% validation rate-limit-check %}
          iterations: 6
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `url` in {% validation rate-limit-check %}.')
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/rate-limit-check/index.html') }

    it 'renders the snippet include for konnect' do
      expect(template_source).to include('{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations url=config.konnect_url')
    end

    it 'renders the snippet include for on-prem' do
      expect(template_source).to include('{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations url=config.on_prem_url')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/rate-limit-check/index.md') }

      it 'renders the snippet include for konnect' do
        expect(template_source).to include('{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations url=config.konnect_url')
      end

      it 'renders the snippet include for on-prem' do
        expect(template_source).to include('{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations url=config.on_prem_url')
      end
    end
  end
end
