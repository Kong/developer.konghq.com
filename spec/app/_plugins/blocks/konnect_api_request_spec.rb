# frozen_string_literal: true

RSpec.describe Jekyll::KonnectApiRequest do
  let(:site_data) { { 'konnect_api_request' => { 'region' => 'us' } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end
  let(:works_on) { %w[konnect] }
  let(:template) do
    <<~LIQUID
      {% konnect_api_request %}
      url: /v2/control-planes
      method: GET
      {% endkonnect_api_request %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    include_examples 'a konnect-only content div'

    context 'when section is cleanup' do
      let(:template) do
        <<~LIQUID
          {% konnect_api_request %}
          url: /v2/control-planes
          method: DELETE
          section: cleanup
          {% endkonnect_api_request %}
        LIQUID
      end

      it 'renders a data-test-cleanup attribute instead of data-test-step' do
        expect(html).to have_css('div.content[data-deployment-topology="konnect"][data-test-cleanup]')
        expect(html).not_to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
      end
    end

    context 'with indent set' do
      let(:template) do
        <<~LIQUID
          {% konnect_api_request %}
          url: /v2/control-planes
          method: GET
          indent: 3
          {% endkonnect_api_request %}
        LIQUID
      end

      it 'applies the requested indent to every line' do
        expect(rendered.lines.reject { |l| l.strip.empty? }).to all(start_with('   '))
      end
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
    end

    it 'renders no wrapping div' do
      expect(rendered).not_to include('<div')
    end
  end

  describe 'works_on validation' do
    context 'when the page does not work on konnect or konnect-platform' do
      let(:works_on) { %w[on-prem] }

      it 'raises an error' do
        expect { rendered }.to raise_error(
          ArgumentError,
          'Page does not contain works_on: konnect or konnect-platform, but uses {% konnect_api_request %}'
        )
      end
    end

    context 'when the page works on konnect-platform' do
      let(:works_on) { %w[konnect-platform] }

      it 'renders without error' do
        expect { rendered }.not_to raise_error
      end
    end
  end

  describe 'yaml validation' do
    context 'missing url' do
      let(:template) do
        <<~LIQUID
          {% konnect_api_request %}
          method: GET
          {% endkonnect_api_request %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `url` in {% konnect_api_request %}.')
      end
    end

    include_examples 'a block that rejects malformed yaml', 'konnect_api_request'
  end
end
