# frozen_string_literal: true

RSpec.describe '{% validation traffic-generator %} rendered command' do
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

  let(:works_on) { %w[konnect] }
  let(:output_format) { 'html' }
  let(:page) do
    { 'output_format' => output_format, 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end

  subject(:rendered) { render_liquid(template, page:) }

  let(:code) { bash_code_block(rendered) }

  shared_examples 'a valid curl command' do
    it 'renders syntactically valid bash' do
      validate_bash_syntax!(code)
    end

    it 'renders the same command in both output formats' do
      html = bash_code_block(render_liquid(template, page: page.merge('output_format' => 'html')))
      markdown = bash_code_block(render_liquid(template, page: page.merge('output_format' => 'markdown')))

      expect(markdown).to eq(html)
    end
  end

  context 'iterations, which the snippet reads as count' do
    let(:template) do
      <<~'LIQUID'
        {% validation traffic-generator %}
        url: /anything
        iterations: 6
        headers:
          - apikey:jsmith-key
        status_code: 200
        {% endvalidation %}
      LIQUID
    end

    include_examples 'a valid curl command'

    it 'renders the exact curl command, repeated 6 times' do
      expect(code).to eq(<<~'BASH'.chomp)
        for _  in {1..6}; do
        curl "https://konnect.example.com/anything" \
             --no-progress-meter --fail-with-body  \
             -H "apikey:jsmith-key" \
        ; done
      BASH
    end
  end

  context 'an option that the template dropped before' do
    let(:template) do
      <<~'LIQUID'
        {% validation traffic-generator %}
        url: /anything
        iterations: 2
        output: response.json
        {% endvalidation %}
      LIQUID
    end

    include_examples 'a valid curl command'

    it 'writes the response to the file' do
      expect(code).to eq(<<~'BASH'.chomp)
        for _  in {1..2}; do
        curl "https://konnect.example.com/anything" \
             -o response.json --no-progress-meter --fail-with-body  \
        ; done
      BASH
    end
  end

  context 'grep, which the block no longer supports' do
    let(:template) do
      <<~'LIQUID'
        {% validation traffic-generator %}
        url: /anything
        iterations: 2
        grep: HTTP
        {% endvalidation %}
      LIQUID
    end

    include_examples 'a valid curl command'

    it 'renders no grep' do
      expect(code).not_to include('grep')
    end
  end

  context 'a page that works on both topologies' do
    let(:works_on) { %w[konnect on-prem] }
    let(:template) do
      <<~'LIQUID'
        {% validation traffic-generator %}
        url: /anything
        iterations: 2
        {% endvalidation %}
      LIQUID
    end
    let(:commands) { rendered.scan(/```bash\n(.*?)\n```/m).flatten }

    it 'renders one command per topology, konnect first' do
      expect(commands.size).to eq(2)
      expect(commands[0]).to include('"https://konnect.example.com/anything"')
      expect(commands[1]).to include('"https://on-prem.example.com/anything"')
    end
  end
end
