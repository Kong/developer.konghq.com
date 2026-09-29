# frozen_string_literal: true

RSpec.describe Jekyll::Validation do
  let(:validations_config) do
    [{ 'id' => 'claude-code', 'command' => 'claude', 'expected' => { 'return_code' => 0 } }]
  end
  let(:how_tos_config) { { 'validations' => validations_config } }
  let(:site_data) { { 'how-tos' => { 'config' => how_tos_config } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) { { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['ai-gateway'] } }
  let(:template) do
    <<~LIQUID
      {% validation claude-code %}
      prompt: Tell me about the Madrid Skylitzes manuscript.
      model: my-claude
      base_url: http://localhost:8000/
      {% endvalidation %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    it 'renders a content div with the markdown attribute' do
      expect(html).to have_css('div.content[markdown="1"]')
    end

    it 'renders a data-test-step attribute' do
      expect(html).to have_css('div.content[data-test-step]')
    end
  end

  context 'when model or prompt is missing' do
    let(:template) do
      <<~LIQUID
        {% validation claude-code %}
        model: my-claude
        {% endvalidation %}
      LIQUID
    end

    it 'raises an error' do
      expect { rendered }.to raise_error(ArgumentError, 'Missing `prompt` in {% validation claude-code %}.')
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/claude-code/index.html') }

    it 'renders the snippet include' do
      expect(template_source).to include('{% include how-tos/validations/claude-code/snippet.md config=config %}')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/claude-code/index.md') }

      it 'renders the snippet include' do
        expect(template_source).to include('{% include how-tos/validations/claude-code/snippet.md config=config %}')
      end
    end
  end
end
