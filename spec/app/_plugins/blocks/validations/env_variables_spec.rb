# frozen_string_literal: true

RSpec.describe Jekyll::Validation do
  let(:how_tos_config) { { 'validations' => [] } }
  let(:site_data) { { 'how-tos' => { 'config' => how_tos_config } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end
  let(:template) do
    <<~LIQUID
      {% validation env-variables %}
      KONNECT_TOKEN: kpat_xxx
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

    context 'when section is prereqs' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% validation env-variables %}
          KONNECT_TOKEN: kpat_xxx
          section: prereqs
          {% endvalidation %}
        LIQUID
      end

      it 'renders a data-test-prereq attribute instead of data-test-step' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][data-test-prereq]')
        expect(html).not_to have_css('div[data-deployment-topology="konnect"][data-test-step]')
      end
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
    end

    context 'works_on: konnect' do
      let(:works_on) { %w[konnect] }

      it 'renders the export line' do
        expect(rendered).to include('export KONNECT_TOKEN="kpat_xxx"')
      end

      it 'does not render a deployment topology heading' do
        expect(rendered).not_to include('### Konnect deployments')
      end
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders the export line for both topologies' do
        expect(rendered.scan('export KONNECT_TOKEN="kpat_xxx"').size).to eq(2)
      end

      it 'renders a deployment topology heading for each, konnect before on-prem' do
        expect(rendered.index('### Konnect deployments')).to be < rendered.index('### On-prem deployments')
      end
    end
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'an empty mapping (see report: a fully blank body raises NoMethodError instead, since ' \
             'YAML.load("") is nil, not {})' do
      let(:template) do
        <<~LIQUID
          {% validation env-variables %}
          {}
          {% endvalidation %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing variables in {% validation env-variables %}.')
      end
    end
  end

  describe '`indent:` stacks with the generic {% validation %} indent (see report — likely unintended)' do
    let(:works_on) { %w[konnect] }
    let(:template) do
      <<~LIQUID
        {% validation env-variables %}
        KONNECT_TOKEN: kpat_xxx
        indent: 3
        {% endvalidation %}
      LIQUID
    end

    it 'indents content by double the requested amount, because index.html applies `indent` ' \
       'itself and Jekyll::Validation#render applies it again on top' do
      content_line = rendered.lines.find { |l| l.include?('export KONNECT_TOKEN') }
      expect(content_line).to start_with(' ' * 6)
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/env-variables/index.html') }

    it 'renders the snippet include' do
      expect(template_source).to include(
        '{% include how-tos/validations/env-variables/snippet.md variables=config.variables %}'
      )
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/env-variables/index.md') }

      it 'renders the snippet include' do
        expect(template_source).to include(
          '{% include how-tos/validations/env-variables/snippet.md variables=config.variables %}'
        )
      end
    end
  end
end
