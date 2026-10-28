# frozen_string_literal: true

RSpec.describe 'info_box/sections/priority' do
  subject(:html) { Capybara::Node::Simple.new(render_liquid(template, page: page_data)) }

  context 'with a learn_more_url param' do
    let(:template) do
      <<~LIQUID
        {% include_cached info_box/sections/priority.html priority=page.priority learn_more_url=page.priority_doc_url %}
      LIQUID
    end

    let(:page_data) do
      {
        'priority' => 750,
        'priority_doc_url' => '/ai-gateway/entities/ai-policy/#ai-policy-priority'
      }
    end

    it 'links the help icon to the passed URL' do
      expect(html).to have_css("a[href='/ai-gateway/entities/ai-policy/#ai-policy-priority']")
    end

    it 'renders the priority value' do
      expect(html).to have_css('span', text: '750')
    end
  end

  context 'without a learn_more_url param' do
    let(:template) do
      <<~LIQUID
        {% include_cached info_box/sections/priority.html priority=page.priority %}
      LIQUID
    end

    let(:page_data) { { 'priority' => 950 } }

    it 'defaults the help link to the Gateway plugin priority doc' do
      expect(html).to have_css("a[href='/gateway/entities/plugin/#plugin-priority']")
    end

    it 'renders the priority value' do
      expect(html).to have_css('span', text: '950')
    end
  end
end
