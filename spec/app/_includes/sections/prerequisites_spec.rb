# frozen_string_literal: true

RSpec.describe 'sections/prerequisites.html' do
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
  let(:page) { page_data.merge('prerequisites' => Jekyll::Drops::Prereqs.new(page: drop_page, site: site)) }
  let(:template) do
    <<~'LIQUID'
      {% include sections/prerequisites.html %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page:) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  context 'a how-to whose only prereq is skip_product' do
    it 'renders the hidden test markers with no visible Prerequisites section' do
      expect(html).to have_css('.prerequisites')
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="on-prem"][data-test-setup="operator"]'
      )
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
      expect(html).to have_no_css('#prerequisites')
    end

    it 'renders no visible accordion content, including the Kong Konnect item' do
      expect(html).to have_no_css('.prerequisites .accordion-item')
      expect(rendered).not_to include('Kong Konnect')
    end
  end

  context 'a how-to that skips the product include but declares operator konnect auth' do
    let(:page_data) do
      {
        'prereqs' => { 'skip_product' => true, 'operator' => { 'konnect' => { 'auth' => true } } },
        'tools' => [],
        'products' => ['operator'],
        'works_on' => ['konnect'],
        'output_format' => 'html'
      }
    end

    it 'renders the visible Prerequisites section with the Kong Konnect item' do
      expect(html).to have_css('#prerequisites')
      expect(html).to have_css('.prerequisites .accordion-item', text: 'Kong Konnect')
      expect(html).to have_css(
        '.prerequisites > [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
    end

    it 'renders the auth creation accordion item' do
      expect(html).to have_css(
        '.prerequisites .accordion-item', text: 'Create a KonnectAPIAuthConfiguration resource'
      )
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

    it 'renders the visible Prerequisites section' do
      expect(html).to have_css('#prerequisites')
      expect(html).to have_css('.prerequisites')
    end
  end
end
