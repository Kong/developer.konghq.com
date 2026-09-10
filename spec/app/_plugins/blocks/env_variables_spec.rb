# frozen_string_literal: true

RSpec.describe Jekyll::EnvVariables do
  let(:how_tos_config) { { 'validations' => [] } }
  let(:site_data) { { 'how-tos' => { 'config' => how_tos_config } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => products, 'works_on' => works_on }
  end
  let(:products) { ['gateway'] }
  let(:template) do
    <<~LIQUID
      {% env_variables %}
      KONNECT_TOKEN: kpat_xxx
      {% endenv_variables %}
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
    end

    context 'works_on: konnect and on-prem' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders both content divs with the markdown attribute' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][markdown="1"]')
        expect(html).to have_css('div[data-deployment-topology="on-prem"][markdown="1"]')
      end
    end

    context 'when section is prereqs' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% env_variables %}
          KONNECT_TOKEN: kpat_xxx
          section: prereqs
          {% endenv_variables %}
        LIQUID
      end

      it 'renders a data-test-prereq attribute instead of data-test-step' do
        expect(html).to have_css('div[data-deployment-topology="konnect"][data-test-prereq]')
        expect(html).not_to have_css('div[data-deployment-topology="konnect"][data-test-step]')
      end
    end

    context 'with no supported product listed (real {% validation %} block would reject this)' do
      let(:works_on) { %w[konnect] }
      let(:products) { ['not-a-real-product'] }

      it 'still renders, since Jekyll::EnvVariables performs no product-type check' do
        expect(html).to have_css('div[data-deployment-topology="konnect"]')
      end
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => products, 'works_on' => works_on }
    end

    context 'works_on: konnect and on-prem, default section' do
      let(:works_on) { %w[konnect on-prem] }

      it 'renders a deployment topology heading for each, konnect before on-prem' do
        expect(rendered.index('Konnect deployments')).to be < rendered.index('On-prem deployments')
      end
    end

    context 'works_on: konnect and on-prem, section: prereqs' do
      let(:works_on) { %w[konnect on-prem] }
      let(:template) do
        <<~LIQUID
          {% env_variables %}
          DECK_IDENTIFIER: SAML-application-identifier
          section: prereqs
          {% endenv_variables %}
        LIQUID
      end

      it 'renders each heading at a hardcoded level 4, not the level ClosestHeading would pick' do
        expect(rendered).to include("\n#### Konnect deployments\n")
        expect(rendered).to include("\n#### On-prem deployments\n")
      end
    end

    context 'indent combined with section: prereqs' do
      let(:works_on) { %w[konnect] }
      let(:template) do
        <<~LIQUID
          {% env_variables %}
          DECK_NGROK_HOST: YOUR-FORWARDING-URL/anything
          indent: 3
          section: prereqs
          {% endenv_variables %}
        LIQUID
      end

      it 'applies the requested indent exactly once, unlike {% validation env-variables %}' do
        content_line = rendered.lines.find { |l| l.include?('export DECK_NGROK_HOST') }
        expect(content_line).to eq("   export DECK_NGROK_HOST=\"YOUR-FORWARDING-URL/anything\"\n")
      end
    end
  end

  describe 'yaml validation' do
    let(:works_on) { %w[konnect] }

    context 'an empty mapping' do
      let(:template) do
        <<~LIQUID
          {% env_variables %}
          {}
          {% endenv_variables %}
        LIQUID
      end

      it 'raises an error, worded for {% validation %} even though this is {% env_variables %}' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing variables in {% validation env-variables %}.')
      end
    end

    context 'malformed yaml' do
      let(:template) do
        <<~LIQUID
          {% env_variables %}
          KEY: 'unterminated
          {% endenv_variables %}
        LIQUID
      end

      it 'raises an error worded for {% env_variables %}' do
        expect { rendered }.to raise_error(ArgumentError, /the following \{% env_variables %\} block contains a malformed yaml/)
      end
    end
  end
end
