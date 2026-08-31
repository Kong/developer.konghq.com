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
      {% validation request-check %}
      url: /mock/anything
      method: GET
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
        expect(html).to have_css('div.content[data-deployment-topology="konnect"][markdown="1"]')
      end

      it 'renders a data-test-step attribute' do
        expect(html).to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
      end

      context 'when config.skip is true' do
        let(:template) do
          <<~LIQUID
            {% validation request-check %}
            url: /mock/anything
            method: GET
            status_code: 200
            skip: true
            {% endvalidation %}
          LIQUID
        end

        it 'does not render a data-test-step attribute' do
          expect(html).not_to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
        end
      end

    end

    context 'works_on: on-prem' do
      let(:works_on) { %w[on-prem] }

      it 'renders an on-prem content div with the markdown attribute' do
        expect(html).to have_css('div.content[data-deployment-topology="on-prem"][markdown="1"]')
      end

      it 'renders a data-test-step attribute' do
        expect(html).to have_css('div.content[data-deployment-topology="on-prem"][data-test-step]')
      end

      context 'when config.skip is true' do
        let(:template) do
          <<~LIQUID
            {% validation request-check %}
            url: /mock/anything
            method: GET
            status_code: 200
            skip: true
            {% endvalidation %}
          LIQUID
        end

        it 'does not render a data-test-step attribute' do
          expect(html).not_to have_css('div.content[data-deployment-topology="on-prem"][data-test-step]')
        end
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both content divs with the markdown attribute' do
        expect(html).to have_css('div.content[data-deployment-topology="konnect"][markdown="1"]')
        expect(html).to have_css('div.content[data-deployment-topology="on-prem"][markdown="1"]')
      end

      it 'renders a data-test-step attribute on both content divs' do
        expect(html).to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
        expect(html).to have_css('div.content[data-deployment-topology="on-prem"][data-test-step]')
      end

      context 'when config.skip is true' do
        let(:template) do
          <<~LIQUID
            {% validation request-check %}
            url: /mock/anything
            method: GET
            status_code: 200
            skip: true
            {% endvalidation %}
          LIQUID
        end

        it 'does not render a data-test-step attribute on either content div' do
          expect(html).not_to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
          expect(html).not_to have_css('div.content[data-deployment-topology="on-prem"][data-test-step]')
        end
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
        expect(rendered).to include('https://konnect.example.com/mock/anything')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### Konnect deployments')
      end
    end

    context 'works_on: on-prem' do
      let(:works_on) { %w[on-prem] }

      it 'renders the on-prem snippet' do
        expect(rendered).to include('https://on-prem.example.com/mock/anything')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### On-prem deployments')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both snippets' do
        expect(rendered).to include('https://konnect.example.com/mock/anything')
        expect(rendered).to include('https://on-prem.example.com/mock/anything')
      end

      it 'renders a deployment topology heading for each, konnect before on-prem' do
        expect(rendered.index('### Konnect deployments')).to be < rendered.index('### On-prem deployments')
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/request-check/index.html') }

    it 'renders the snippet include for konnect' do
      expect(template_source).to include('{% include how-tos/validations/request-check/snippet.md url=config.konnect_url')
    end

    it 'renders the snippet include for on-prem' do
      expect(template_source).to include('{% include how-tos/validations/request-check/snippet.md url=config.on_prem_url')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/request-check/index.md') }

      it 'renders the snippet include for konnect' do
        expect(template_source).to include('{% include how-tos/validations/request-check/snippet.md url=config.konnect_url')
      end

      it 'renders the snippet include for on-prem' do
        expect(template_source).to include('{% include how-tos/validations/request-check/snippet.md url=config.on_prem_url')
      end
    end
  end
end
