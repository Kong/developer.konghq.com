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
    it 'still declares the operator test setup in a hidden div' do
      expect(html).to have_css(
        '.prerequisites [data-deployment-topology="on-prem"][data-test-setup="operator"]'
      )
    end

    it 'renders no visible prereq content for the operator' do
      expect(html).to have_css('.prerequisites')
      expect(html).to have_no_css('.prerequisites .accordion-item')
    end
  end
end
