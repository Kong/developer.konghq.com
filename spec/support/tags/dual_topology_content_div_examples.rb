# frozen_string_literal: true

RSpec.shared_examples 'a dual-topology content div' do
  context 'works_on: konnect' do
    let(:works_on) { %w[konnect] }

    it 'renders a konnect content div with the markdown attribute' do
      expect(html).to have_css('div.content[data-deployment-topology="konnect"][markdown="1"]')
    end

    it 'renders a data-test-step attribute' do
      expect(html).to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
    end

    it 'does not render an on-prem content div' do
      expect(html).not_to have_css('div.content[data-deployment-topology="on-prem"]')
    end
  end

  context 'works_on: on-prem' do
    let(:works_on) { %w[on-prem] }

    it 'renders an on-prem content div with the markdown attribute' do
      expect(html).to have_css('div.content[data-deployment-topology="on-prem"][markdown="1"]')
    end

    it 'renders a data-test-step attribute' do
      expect(html).to have_css('div.content[data-deployment-topology="on-prem"][data-test-step]')
    end

    it 'does not render a konnect content div' do
      expect(html).not_to have_css('div.content[data-deployment-topology="konnect"]')
    end
  end

  context 'works_on: konnect and on-prem' do
    let(:works_on) { %w[konnect on-prem] }

    it 'renders both content divs with the markdown attribute' do
      expect(html).to have_css('div.content[data-deployment-topology="konnect"][markdown="1"]')
      expect(html).to have_css('div.content[data-deployment-topology="on-prem"][markdown="1"]')
    end

    it 'renders a data-test-step attribute on both content divs' do
      expect(html).to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
      expect(html).to have_css('div.content[data-deployment-topology="on-prem"][data-test-step]')
    end
  end
end

RSpec.shared_examples 'a konnect-only content div' do
  it 'renders a konnect content div with the markdown attribute' do
    expect(html).to have_css('div.content[data-deployment-topology="konnect"][markdown="1"]')
  end

  it 'renders a data-test-step attribute' do
    expect(html).to have_css('div.content[data-deployment-topology="konnect"][data-test-step]')
  end
end

def render_liquid_with_section(template, page, section)
  modified = template.sub(/(\{% end\w+ %})/) { "section: #{section}\n#{Regexp.last_match(1)}" }
  Capybara::Node::Simple.new(render_liquid(modified, page: page))
end

SECTION_TEST_ATTRIBUTES = {
  'prereqs' => 'data-test-prereq',
  'cleanup' => 'data-test-cleanup'
}.freeze

RSpec.shared_examples 'a section-aware konnect-only content div' do
  SECTION_TEST_ATTRIBUTES.each do |section, attr|
    context "section: #{section}" do
      let(:section_html) { render_liquid_with_section(template, page, section) }
      let(:other_attrs) { %w[data-test-step data-test-prereq data-test-cleanup] - [attr] }

      it "renders #{attr} instead of data-test-step" do
        expect(section_html).to have_css(%(div.content[data-deployment-topology="konnect"][#{attr}]))
      end

      it 'does not render the other test attributes' do
        other_attrs.each do |other_attr|
          expect(section_html).not_to have_css(%(div.content[data-deployment-topology="konnect"][#{other_attr}]))
        end
      end

      it 'keeps the attribute value unchanged from the step case' do
        step_value = html.find('div.content[data-deployment-topology="konnect"]')['data-test-step']
        section_value = section_html.find('div.content[data-deployment-topology="konnect"]')[attr]
        expect(section_value).to eq(step_value)
      end
    end
  end
end

RSpec.shared_examples 'a section-aware dual-topology content div' do
  SECTION_TEST_ATTRIBUTES.each do |section, attr|
    context "section: #{section}" do
      let(:works_on) { %w[konnect on-prem] }
      let(:section_html) { render_liquid_with_section(template, page, section) }
      let(:other_attrs) { %w[data-test-step data-test-prereq data-test-cleanup] - [attr] }

      it "renders #{attr} on both content divs" do
        expect(section_html).to have_css(%(div.content[data-deployment-topology="konnect"][#{attr}]))
        expect(section_html).to have_css(%(div.content[data-deployment-topology="on-prem"][#{attr}]))
      end

      it 'does not render the other test attributes on either div' do
        other_attrs.each do |other_attr|
          expect(section_html).not_to have_css(%(div.content[data-deployment-topology="konnect"][#{other_attr}]))
          expect(section_html).not_to have_css(%(div.content[data-deployment-topology="on-prem"][#{other_attr}]))
        end
      end

      it 'keeps the attribute value unchanged from the step case on both divs' do
        konnect_step_value = html.find('div.content[data-deployment-topology="konnect"]')['data-test-step']
        on_prem_step_value = html.find('div.content[data-deployment-topology="on-prem"]')['data-test-step']

        section_konnect_value = section_html.find('div.content[data-deployment-topology="konnect"]')[attr]
        section_on_prem_value = section_html.find('div.content[data-deployment-topology="on-prem"]')[attr]

        expect(section_konnect_value).to eq(konnect_step_value)
        expect(section_on_prem_value).to eq(on_prem_step_value)
      end
    end
  end
end
