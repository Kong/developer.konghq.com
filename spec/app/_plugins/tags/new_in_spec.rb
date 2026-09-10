# frozen_string_literal: true

RSpec.describe Jekyll::RenderNewIn do
  let(:page) { { 'output_format' => format } }
  let(:locals) { {} }

  subject { render_liquid(template, page:, locals:) }

  describe 'rendering (markdown output)' do
    let(:format) { 'markdown' }
    let(:template) { '{% new_in 3.8 %}' }

    it 'renders the version with a v prefix and + suffix' do
      expect(subject).to include('v3.8+')
    end

    context 'using variables' do
      let(:locals)  { { 'min_version' => '2.5' } }
      let(:template) { '{% new_in min_version %}' }

      it 'resolves the version from a context variable' do
        expect(subject).to include('v2.5+')
      end
    end
  end

  describe 'rendering (html output)' do
    let(:format) { 'html' }
    let(:locals) { { 'min_version' => '2.5' } }
    let(:template) { '{% new_in min_version %}' }
    let(:html) { Capybara::Node::Simple.new(subject) }

    it 'resolves the version from a context variable' do
      expect(html).to have_css('.badge.new-in', text: 'v2.5+')
    end
  end

  describe 'validation' do
    let(:format) { 'markdown' }
    let(:template) { '{% new_in %}' }

    it 'raises ArgumentError when no version is given' do
      expect { subject }.to raise_error(ArgumentError, /version/)
    end
  end
end
