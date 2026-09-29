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
    include_examples 'a dual-topology content div'
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

    it 'passes the konnect snippet config to the snippet' do
      expect(template_source).to include('snippet.md config=config.konnect_snippet_config %}')
    end

    it 'passes the on-prem snippet config to the snippet' do
      expect(template_source).to include('snippet.md config=config.on_prem_snippet_config %}')
    end

    it 'passes the snippet nothing else' do
      expect(template_source.scan(/snippet\.md ([^%]*)%\}/).flatten)
        .to eq(['config=config.konnect_snippet_config ', 'config=config.on_prem_snippet_config '])
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/traffic-generator/index.md') }

      it 'passes the konnect snippet config to the snippet' do
        expect(template_source).to include('snippet.md config=config.konnect_snippet_config %}')
      end

      it 'passes the on-prem snippet config to the snippet' do
        expect(template_source).to include('snippet.md config=config.on_prem_snippet_config %}')
      end

      it 'passes the snippet nothing else' do
        expect(template_source.scan(/snippet\.md ([^%]*)%\}/).flatten)
          .to eq(['config=config.konnect_snippet_config ', 'config=config.on_prem_snippet_config '])
      end
    end
  end
end
