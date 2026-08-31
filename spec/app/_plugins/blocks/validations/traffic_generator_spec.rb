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
      {% validation traffic-generator %}
      iterations: 6
      url: /anything
      headers:
        - 'apikey:jsmith-key'
      status_code: 200
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

      it 'delegates to request-check/snippet.md, looping `iterations` times via `count`' do
        expect(rendered).to include('for _  in {1..6}; do')
        expect(rendered).to include('-H "apikey:jsmith-key"')
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

    context 'with a method, body, and inline_sleep' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% validation traffic-generator %}
          iterations: 5
          url: /anything
          method: POST
          status_code: 200
          body:
            messages:
              - role: user
                content: Who was Jozef Mackiewicz?
          inline_sleep: 3
          {% endvalidation %}
        LIQUID
      end

      it 'passes method/body/inline_sleep through to the delegated curl command' do
        expect(rendered).to include('-X POST')
        expect(rendered).to include('"content": "Who was Jozef Mackiewicz?"')
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
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'missing iterations' do
      let(:template) do
        <<~LIQUID
          {% validation traffic-generator %}
          url: /anything
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `iterations` in {% validation traffic-generator %}.')
      end
    end

    context 'grep specified with no output.expected (synthetic — no real doc uses grep here)' do
      let(:template) do
        <<~LIQUID
          {% validation traffic-generator %}
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

    context 'missing url' do
      let(:template) do
        <<~LIQUID
          {% validation traffic-generator %}
          iterations: 6
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `url` in {% validation traffic-generator %}.')
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/traffic-generator/index.html') }

    it 'delegates to request-check/snippet.md for konnect, mapping iterations to count' do
      expect(template_source).to include(
        '{% include how-tos/validations/request-check/snippet.md url=config.konnect_url'
      )
      expect(template_source).to include('count=config.iterations')
    end

    it 'delegates to request-check/snippet.md for on-prem, mapping iterations to count' do
      expect(template_source).to include(
        '{% include how-tos/validations/request-check/snippet.md url=config.on_prem_url'
      )
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/traffic-generator/index.md') }

      it 'delegates to request-check/snippet.md for konnect, mapping iterations to count' do
        expect(template_source).to include(
          '{% include how-tos/validations/request-check/snippet.md url=config.konnect_url'
        )
        expect(template_source).to include('count=config.iterations')
      end

      it 'delegates to request-check/snippet.md for on-prem, mapping iterations to count' do
        expect(template_source).to include(
          '{% include how-tos/validations/request-check/snippet.md url=config.on_prem_url'
        )
      end
    end
  end
end
