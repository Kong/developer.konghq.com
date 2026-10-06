# frozen_string_literal: true

RSpec.describe 'prereqs tag' do
  let(:page_data) do
    {
      'prereqs' => { 'skip_product' => true },
      'tools' => [],
      'products' => ['operator'],
      'works_on' => %w[konnect on-prem],
      'output_format' => 'html'
    }
  end
  let(:drop_page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
  let(:site) { instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source') }
  let(:drop) { Jekyll::Drops::Prereqs.new(page: drop_page, site: site) }
  let(:page) { page_data.merge('prerequisites' => drop) }
  let(:template) do
    <<~'LIQUID'
      {% prereqs %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page:) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  context 'a how-to whose only prereq is skip_product' do
    it 'renders the prereqs container with the hidden test markers' do
      expect(html).to have_css('.prerequisites')
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="on-prem"][data-test-setup="operator"]'
      )
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
    end
  end

  context 'a markers-only how-to for a product with no marker support' do
    let(:page_data) do
      {
        'prereqs' => { 'skip_product' => true },
        'tools' => [],
        'products' => ['gateway'],
        'works_on' => ['on-prem'],
        'output_format' => 'html'
      }
    end

    it 'renders nothing' do
      expect(rendered.strip).to be_empty
    end
  end

  context 'a markers-only how-to rendered as markdown' do
    let(:page_data) do
      super().merge('output_format' => 'markdown')
    end

    it 'renders nothing' do
      expect(rendered.strip).to be_empty
    end
  end

  context 'a how-to with visible prereqs' do
    let(:page_data) do
      {
        'prereqs' => {},
        'tools' => ['deck'],
        'products' => ['operator'],
        'works_on' => ['on-prem'],
        'output_format' => 'html'
      }
    end

    it 'renders the prereqs container' do
      expect(html).to have_css('.prerequisites')
    end
  end
end
