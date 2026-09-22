# frozen_string_literal: true

RSpec.describe '{% konnect_api_request %} rendered command' do
  let(:site_data) { { 'konnect_api_request' => { 'region' => 'us' } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:output_format) { 'html' }
  let(:page) do
    { 'output_format' => output_format, 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => %w[konnect] }
  end

  subject(:rendered) { render_liquid(template, page:) }

  let(:code) { bash_code_block(rendered) }
  let(:commands) { rendered.scan(/```bash\n(.*?)\n```/m).flatten }

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

  context 'a plain request' do
    let(:template) do
      <<~'LIQUID'
        {% konnect_api_request %}
        url: /v2/control-planes
        method: POST
        status_code: 201
        {% endkonnect_api_request %}
      LIQUID
    end

    include_examples 'a valid curl command'

    it 'renders one command against the region api host, with the bearer token' do
      expect(commands.size).to eq(1)
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "https://us.api.konghq.com/v2/control-planes" \
             --no-progress-meter --fail-with-body  \
             -H "Authorization: Bearer $KONNECT_TOKEN"
      BASH
    end
  end

  context 'a writer-supplied header' do
    let(:template) do
      <<~'LIQUID'
        {% konnect_api_request %}
        url: /v2/control-planes
        headers:
          - 'Content-Type: application/json'
        {% endkonnect_api_request %}
      LIQUID
    end

    include_examples 'a valid curl command'

    it 'renders the writer header and the authorization header once each' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl "https://us.api.konghq.com/v2/control-planes" \
             --no-progress-meter --fail-with-body  \
             -H "Authorization: Bearer $KONNECT_TOKEN"\
             -H "Content-Type: application/json"
      BASH
    end
  end

  context 'an option that the template dropped before' do
    let(:template) do
      <<~'LIQUID'
        {% konnect_api_request %}
        url: /v2/control-planes
        expected_headers:
          - 'X-Kong-Admin: true'
        {% endkonnect_api_request %}
      LIQUID
    end

    include_examples 'a valid curl command'

    it 'renders the expected header outside the curl command' do
      expect(rendered).to include('You should see the following header:')
      expect(rendered).to include('X-Kong-Admin: true')
    end
  end

  context 'a page that also works on-prem' do
    let(:template) do
      <<~'LIQUID'
        {% konnect_api_request %}
        url: /v2/control-planes
        {% endkonnect_api_request %}
      LIQUID
    end
    let(:page) do
      {
        'output_format' => 'html',
        'path' => 'test.md',
        'products' => ['gateway'],
        'works_on' => %w[konnect on-prem]
      }
    end

    it 'still renders one command only' do
      expect(commands.size).to eq(1)
    end
  end
end
