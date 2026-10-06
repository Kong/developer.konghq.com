# frozen_string_literal: true

RSpec.describe 'components/prereqs.html' do
  let(:template) do
    <<~'LIQUID'
      {% include components/prereqs.html %}
    LIQUID
  end
  let(:page) do
    {
      'output_format' => 'html',
      'path' => 'test.md',
      'products' => ['operator'],
      'works_on' => %w[konnect on-prem]
    }
  end
  let(:locals) { { 'prereqs' => { 'skip_product' => true } } }

  subject(:rendered) { render_liquid(template, page:, locals:) }

  def html
    Capybara::Node::Simple.new(rendered)
  end

  context 'an operator how-to that skips the product include' do
    it 'still declares the operator test setup in a hidden div per works_on platform' do
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="on-prem"][data-test-setup="operator"]'
      )
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
    end

    it 'renders no visible prereq content for the operator' do
      expect(html).to have_css('.prerequisites')
      expect(html).to have_no_css('.prerequisites .accordion-item')
    end
  end

  context 'an operator how-to that skips the product include and only works on konnect' do
    let(:page) do
      {
        'output_format' => 'html',
        'path' => 'test.md',
        'products' => ['operator'],
        'works_on' => ['konnect']
      }
    end

    it 'declares only the konnect operator marker' do
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
      expect(html).to have_no_css('.prerequisites [data-deployment-topology="on-prem"]')
    end
  end

  context 'an operator how-to that needs only konnect auth' do
    let(:page_data) do
      {
        'prereqs' => {},
        'tools' => [],
        'products' => ['operator'],
        'works_on' => ['konnect'],
        'output_format' => 'html'
      }
    end
    let(:drop_page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
    let(:site) { instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source') }
    let(:locals) { { 'prereqs' => Jekyll::Drops::Prereqs.new(page: drop_page, site: site) } }

    it 'declares the operator test setup on the konnect auth prereq' do
      expect(html).to have_css(
        '.prerequisites > [data-deployment-topology="konnect"][data-test-setup="operator"]'
      )
    end
  end

  context 'a non-operator how-to that needs only konnect auth' do
    let(:page) do
      {
        'output_format' => 'html',
        'path' => 'test.md',
        'products' => ['mesh'],
        'works_on' => ['konnect']
      }
    end
    let(:page_data) do
      {
        'prereqs' => {},
        'tools' => [],
        'products' => ['mesh'],
        'works_on' => ['konnect'],
        'output_format' => 'html'
      }
    end
    let(:drop_page) { instance_double(Jekyll::Page, data: page_data, url: '/test/') }
    let(:site) { instance_double(Jekyll::Site, data: { 'products' => {} }, source: '/source') }
    let(:locals) { { 'prereqs' => Jekyll::Drops::Prereqs.new(page: drop_page, site: site) } }

    it 'keeps the konnect test setup value' do
      expect(html).to have_css(
        '.prerequisites > [data-deployment-topology="konnect"][data-test-setup="konnect"]'
      )
    end
  end
end
