# frozen_string_literal: true

RSpec.describe Jekyll::HttpRequest do
  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'products' => ['gateway'] }
  end
  let(:template) do
    <<~LIQUID
      {% http_request %}
      url: /mock/anything
      method: GET
      {% endhttp_request %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    it 'renders a content div with the markdown attribute' do
      expect(html).to have_css('div[markdown="1"]')
    end

    it 'renders a data-test-step attribute' do
      expect(html).to have_css('div[data-test-step]')
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'products' => ['gateway'] }
    end

    it 'renders no wrapping div' do
      expect(rendered).not_to include('<div')
    end
  end

  describe 'yaml validation' do
    context 'missing url' do
      let(:template) do
        <<~LIQUID
          {% http_request %}
          method: GET
          {% endhttp_request %}
        LIQUID
      end

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, 'Missing `url` in {% http_request %}.')
      end
    end

    include_examples 'a block that rejects malformed yaml', 'http_request'
  end
end
