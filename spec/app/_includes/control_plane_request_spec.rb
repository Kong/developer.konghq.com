# frozen_string_literal: true

RSpec.describe '{% control_plane_request %} rendered command' do
  let(:url_origin) do
    { 'konnect' => 'https://konnect.example.com', 'on_prem' => 'http://localhost:8001' }
  end
  let(:site_data) { { 'control_plane_request' => { 'url_origin' => url_origin } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:works_on) { %w[konnect] }
  let(:output_format) { 'html' }
  let(:page) do
    { 'output_format' => output_format, 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => works_on }
  end
  let(:block_yaml) { config.to_yaml.delete_prefix("---\n") }
  let(:template) { "{% control_plane_request %}\n#{block_yaml}{% endcontrol_plane_request %}\n" }

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
    let(:config) { { 'url' => '/services', 'method' => 'POST', 'status_code' => 201 } }

    include_examples 'a valid curl command'

    it 'renders the exact curl command' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X POST "https://konnect.example.com/services" \
             --no-progress-meter --fail-with-body 
      BASH
    end
  end

  context 'an option that the template dropped before' do
    let(:config) do
      {
        'url' => '/services',
        'method' => 'POST',
        'capture' => [{ 'variable' => 'SERVICE_ID', 'jq' => '.id' }]
      }
    end

    include_examples 'a valid curl command'

    it 'assigns the captured value to the named shell variable' do
      expect(code).to eq(<<~'BASH'.chomp)
        SERVICE_ID=$(curl -X POST "https://konnect.example.com/services" \
             --no-progress-meter --fail-with-body  | jq -r ".id"
        )
      BASH
    end
  end

  context 'display_headers, the option that 2 how-to pages already set' do
    let(:config) { { 'url' => '/routes', 'display_headers' => true } }
    let(:works_on) { %w[on-prem] }

    include_examples 'a valid curl command'

    it 'renders the -i flag' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -i "http://localhost:8001/routes" \
             --no-progress-meter --fail-with-body 
      BASH
    end
  end

  context 'a page that works on both topologies' do
    let(:works_on) { %w[konnect on-prem] }
    let(:config) { { 'url' => '/services' } }

    it 'renders one command per topology, konnect first' do
      expect(commands.size).to eq(2)
      expect(commands[0]).to include('"https://konnect.example.com/services"')
      expect(commands[1]).to include('"http://localhost:8001/services"')
    end
  end
end
