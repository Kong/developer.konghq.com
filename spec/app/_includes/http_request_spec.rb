# frozen_string_literal: true

RSpec.describe '{% http_request %} rendered command' do
  let(:output_format) { 'html' }
  let(:page) do
    { 'output_format' => output_format, 'path' => 'test.md', 'products' => ['gateway'], 'works_on' => %w[konnect] }
  end
  let(:block_yaml) { config.to_yaml.delete_prefix("---\n") }
  let(:template) { "{% http_request %}\n#{block_yaml}{% endhttp_request %}\n" }

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
    let(:config) do
      { 'url' => 'localhost:8000/anything', 'method' => 'GET', 'headers' => ['apikey: my-key'] }
    end

    include_examples 'a valid curl command'

    it 'renders one command against the url the writer set' do
      expect(commands.size).to eq(1)
      expect(code).to eq(<<~'BASH'.chomp)
        curl -X GET "localhost:8000/anything" \
             --no-progress-meter --fail-with-body  \
             -H "apikey: my-key"
      BASH
    end
  end

  context 'an option that the template dropped before' do
    let(:config) { { 'url' => 'localhost:8000/anything', 'count' => 3 } }

    include_examples 'a valid curl command'

    it 'repeats the request 3 times' do
      expect(code).to eq(<<~'BASH'.chomp)
        for _  in {1..3}; do
        curl "localhost:8000/anything" \
             --no-progress-meter --fail-with-body  \
        ; done
      BASH
    end
  end

  context 'insecure over https' do
    let(:config) { { 'url' => 'localhost:8443/anything', 'insecure' => true } }

    include_examples 'a valid curl command'

    it 'renders -k and the https scheme' do
      expect(code).to eq(<<~'BASH'.chomp)
        curl -k "https://localhost:8443/anything" \
             --no-progress-meter --fail-with-body 
      BASH
    end
  end
end
