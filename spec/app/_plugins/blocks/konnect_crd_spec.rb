# frozen_string_literal: true

RSpec.describe Jekyll::KonnectCrd do
  let(:page) do
    { 'output_format' => 'html', 'path' => 'test.md', 'works_on' => works_on }
  end
  let(:works_on) { %w[konnect] }

  let(:template) do
    <<~'LIQUID'
      {% konnect_crd %}
      kind: KonnectAPIAuthConfiguration
      metadata:
        name: konnect-api-auth
        namespace: kong
      {% endkonnect_crd %}
    LIQUID
  end

  subject(:rendered) { render_liquid(template, page: page) }

  let(:html) { Capybara::Node::Simple.new(rendered) }

  describe 'html output' do
    it 'renders a data-test-step wrapper' do
      expect(html).to have_css('div[data-deployment-topology="konnect"][data-test-step="block"]')
    end

    it 'does not render a data-test-prereq attribute' do
      expect(html).not_to have_css('div[data-test-prereq]')
    end

    context 'without works_on: konnect' do
      let(:works_on) { %w[on-prem] }

      it 'raises an error' do
        expect { rendered }.to raise_error(ArgumentError, /does not contain works_on: konnect/)
      end
    end
  end

  describe 'html output with section: prereqs' do
    let(:template) do
      <<~'LIQUID'
        {% konnect_crd %}
        kind: KonnectAPIAuthConfiguration
        metadata:
          name: konnect-api-auth
          namespace: kong
        section: prereqs
        {% endkonnect_crd %}
      LIQUID
    end

    it 'renders a data-test-prereq wrapper' do
      expect(html).to have_css('div[data-deployment-topology="konnect"][data-test-prereq="block"]')
      expect(html).not_to have_css('div[data-test-step]')
    end

    it 'strips the section key from the emitted YAML' do
      expect(rendered).not_to include('section')
    end
  end

  describe 'markdown output_format' do
    let(:page) do
      { 'output_format' => 'markdown', 'path' => 'test.md', 'works_on' => works_on }
    end

    let(:with_section) do
      <<~'LIQUID'
        {% konnect_crd %}
        kind: KonnectAPIAuthConfiguration
        metadata:
          name: konnect-api-auth
          namespace: kong
        section: prereqs
        {% endkonnect_crd %}
      LIQUID
    end

    it 'renders identically with and without section: prereqs' do
      expect(render_liquid(with_section, page: page)).to eq(rendered)
    end

    it 'strips the section key from the emitted YAML' do
      expect(render_liquid(with_section, page: page)).not_to include('section')
    end

    it 'does not leak html test attributes into the markdown' do
      expect(rendered).not_to include('data-test')
    end
  end
end
