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
