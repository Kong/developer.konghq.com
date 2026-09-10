# frozen_string_literal: true

RSpec.describe Jekyll::Validation do
  let(:validations_config) do
    [{ 'id' => 'codex', 'command' => 'codex', 'expected' => { 'return_code' => 0 } }]
  end
  let(:how_tos_config) { { 'validations' => validations_config } }
  let(:site_data) { { 'how-tos' => { 'config' => how_tos_config } } }
  let(:site) { instance_double(Jekyll::Site, data: site_data) }

  before { allow(Jekyll).to receive(:sites).and_return([site]) }

  let(:page) { { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['ai-gateway'] } }
  let(:template) do
    <<~LIQUID
      {% validation codex %}
      model: codex-openai
      model_provider: my-gateway
      model_provider_name: AI Quickstart
      model_provider_base_url: http://localhost:8000/
      model_provider_env_key: OPENAI_API_KEY
      model_provider_wire_api: responses
      prompt: Tell me about the Madrid Skylitzes manuscript.
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

  describe 'yaml validation' do
    %w[
      prompt model model_provider model_provider_name
      model_provider_base_url model_provider_env_key model_provider_wire_api
    ].each do |field|
      context "when #{field} is missing" do
        let(:template) do
          fields = {
            'model' => 'model: codex-openai',
            'model_provider' => 'model_provider: my-gateway',
            'model_provider_name' => 'model_provider_name: AI Quickstart',
            'model_provider_base_url' => 'model_provider_base_url: http://localhost:8000/',
            'model_provider_env_key' => 'model_provider_env_key: OPENAI_API_KEY',
            'model_provider_wire_api' => 'model_provider_wire_api: responses',
            'prompt' => 'prompt: Tell me about the Madrid Skylitzes manuscript.'
          }.except(field)

          <<~LIQUID
            {% validation codex %}
            #{fields.values.join("\n")}
            {% endvalidation %}
          LIQUID
        end

        it 'raises an error' do
          expect { rendered }.to raise_error(ArgumentError, "Missing `#{field}` in {% validation codex %}.")
        end
      end
    end
  end

  describe 'template source' do
    subject(:template_source) { File.read('app/_includes/how-tos/validations/codex/index.html') }

    it 'renders the snippet include' do
      expect(template_source).to include('{% include how-tos/validations/codex/snippet.md config=config %}')
    end

    context 'markdown template' do
      subject(:template_source) { File.read('app/_includes/how-tos/validations/codex/index.md') }

      it 'renders the snippet include' do
        expect(template_source).to include('{% include how-tos/validations/codex/snippet.md config=config %}')
      end
    end
  end
end
