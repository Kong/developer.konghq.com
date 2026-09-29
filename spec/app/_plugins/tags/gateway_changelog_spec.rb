# frozen_string_literal: true

RSpec.describe Jekyll::RenderGatewayChangelog do
  let(:page) { { 'output_format' => format } }
  let(:locals) { {} }
  let(:template) { '{% gateway_changelog %}' }

  subject { render_liquid(template, page:, locals:) }

  describe 'rendering (markdown output)' do
    let(:format) { 'markdown' }
    let(:sections) { subject.split(/\n(?=## )/).reject(&:empty?) }
    let(:v390_section) { sections.find { |s| s.include?('## 3.9.0.0') } }
    let(:v380_section) { sections.find { |s| s.include?('## 3.8.0.0') } }

    it 'renders each version as a level-2 heading' do
      expect(subject).to include('## 3.9.0.0')
      expect(subject).to include('## 3.8.0.0')
    end

    it 'orders versions newest-first' do
      expect(subject.index('3.9.0.0')).to be < subject.index('3.8.0.0')
    end

    it 'places each release date in its version section' do
      expect(v390_section).to include('2024/09/18')
      expect(v380_section).to include('2024/06/19')
    end

    it 'does not mix release dates across versions' do
      expect(v390_section).not_to include('2024/06/19')
      expect(v380_section).not_to include('2024/09/18')
    end

    it 'places entries in their version section' do
      expect(v390_section).to include('Added new routing capability')
      expect(v380_section).to include('Fixed a critical bug in request handling')
    end

    it 'does not mix entries across versions' do
      expect(v390_section).not_to include('Fixed a critical bug in request handling')
      expect(v380_section).not_to include('Added new routing capability')
    end

    it 'renders the entry type as a level-3 heading' do
      expect(subject).to include('### Feature')
    end

    it 'renders Kong Manager scope entries under the Kong Manager heading' do
      expect(subject).to include('#### Kong Manager')
      expect(subject).to include('Updated dashboard layout')
    end
  end

  context 'when page products is ai-gateway' do
    let(:page) { { 'output_format' => format, 'products' => ['ai-gateway'] } }

    describe 'rendering (markdown output)' do
      let(:format) { 'markdown' }

      it 'renders ai-gateway versions' do
        expect(subject).to include('## 2.0.0')
        expect(subject).to include('## 1.0.0')
      end

      it 'orders versions newest-first' do
        expect(subject.index('2.0.0')).to be < subject.index('1.0.0')
      end

      it 'includes ai-gateway release dates' do
        expect(subject).to include('2025/01/15')
      end

      it 'does not include gateway versions' do
        expect(subject).not_to include('3.9.0.0')
      end
    end

    describe 'rendering (html output)' do
      let(:format) { 'html' }
      let(:html) { Capybara::Node::Simple.new(subject) }

      it 'renders ai-gateway versions as h2 elements' do
        expect(html).to have_css('h2', text: '2.0.0')
        expect(html).to have_css('h2', text: '1.0.0')
      end

      it 'does not render gateway versions' do
        expect(html).not_to have_css('h2', text: '3.9.0.0')
      end
    end
  end

  describe 'rendering (html output)' do
    let(:format) { 'html' }
    let(:html) { Capybara::Node::Simple.new(subject) }

    it 'renders each version as an h2 element' do
      expect(html).to have_css('h2', text: '3.9.0.0')
      expect(html).to have_css('h2', text: '3.8.0.0')
    end

    it 'orders versions newest-first' do
      headings = html.all('h2').map(&:text).map(&:strip)
      expect(headings.index('3.9.0.0')).to be < headings.index('3.8.0.0')
    end

    it 'places each release date as the adjacent sibling of its version heading' do
      expect(html).to have_css('h2[id="3-9-0-0"] + p', text: '2024/09/18')
      expect(html).to have_css('h2[id="3-8-0-0"] + p', text: '2024/06/19')
    end

    it 'places entries under their version heading' do
      expect(html).to have_css('h3[id*="3-9-0-0"] + h4 + ul li', text: 'Added new routing capability')
      expect(html).to have_css('h3[id*="3-8-0-0"] + h4 + ul li', text: 'Fixed a critical bug in request handling')
    end

    it 'renders the entry type as an h3 element' do
      expect(html).to have_css('h3', text: 'Feature')
    end

    it 'renders Kong Manager scope entries under a Kong Manager heading' do
      expect(html).to have_css('h4', text: 'Kong Manager')
      expect(html).to have_css('li', text: 'Updated dashboard layout')
    end
  end
end
