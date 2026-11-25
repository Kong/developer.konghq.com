# frozen_string_literal: true

RSpec.describe Jekyll::RenderToolChangelog do
  let(:page) { { 'output_format' => format } }

  subject(:rendered) { render_liquid(template, page:) }

  describe 'rendering (markdown output)' do
    let(:format) { 'markdown' }
    let(:template) do
      <<~'LIQUID'
        {% tool_changelog tool="kong-harnesses" %}
      LIQUID
    end

    it 'renders the versions from the named changelog file' do
      expect(rendered).to include('## 0.19.0')
      expect(rendered).to include('## 0.18.0')
    end

    it 'renders the entry types as level-3 headings' do
      expect(rendered).to include('### Feature')
    end
  end

  describe 'rendering (html output)' do
    let(:format) { 'html' }
    let(:template) do
      <<~'LIQUID'
        {% tool_changelog tool="kong-harnesses" %}
      LIQUID
    end
    let(:html) { Capybara::Node::Simple.new(rendered) }

    it 'renders the versions as h2 elements' do
      expect(html).to have_css('h2', text: '0.19.0')
    end

    it 'renders the entry types as h3 elements' do
      expect(html).to have_css('h3', text: 'Feature')
    end

    it 'renders the h2 as a plain heading, without a link' do
      heading = html.find('h2', text: '0.19.0')
      expect(heading).to have_no_css('a.link-anchor')
    end

    it 'shows a Liquid-like message sequence literally' do
      expect(html).to have_css('li', text: 'keep ${{ env.VAR }} and {% if true %}literal{% endif %}')
    end
  end

  context 'with a tool argument naming another file' do
    let(:format) { 'markdown' }
    let(:template) do
      <<~'LIQUID'
        {% tool_changelog tool="gateway" %}
      LIQUID
    end

    it 'renders the changelog of the named tool' do
      expect(rendered).to include('3.9.0.0')
    end
  end

  context 'without a tool argument' do
    let(:format) { 'markdown' }
    let(:template) { '{% tool_changelog %}' }

    it 'raises an argument error' do
      expect { rendered }.to raise_error(ArgumentError, /Missing required parameter `tool`/)
    end
  end
end
