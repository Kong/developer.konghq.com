# frozen_string_literal: true

RSpec.describe Jekyll::KumaSpecific::TabsBlock do
  let(:page) { { 'output_format' => 'markdown', 'path' => 'test.md', 'content' => '' } }
  let(:locals) { {} }

  subject { render_liquid(template, page: page, locals: locals) }

  describe 'rendering' do
    context 'with a single level of tabs' do
      let(:template) do
        <<~LIQUID
          {% tabs %}
          {% tab First %}
          content
          {% endtab %}
          {% endtabs %}
        LIQUID
      end

      it 'renders the tab title as a heading' do
        expect(subject).to include('First')
      end
    end

    context 'with tabs nested inside another tab' do
      let(:template) do
        <<~LIQUID
          {% tabs %}
          {% tab ClusterRole %}
          {% tabs codeblock %}
          {% tab name1 %}
          content
          {% endtab %}
          {% endtabs %}
          {% endtab %}
          {% endtabs %}
        LIQUID
      end

      it 'renders the outer tab as an h3' do
        expect(subject).to include('### ClusterRole')
      end

      it 'renders the nested tab as an h4, one level deeper than the outer tab' do
        expect(subject).to include('#### name1')
      end

      it 'renders the outer heading before the nested heading' do
        expect(subject.index('### ClusterRole')).to be < subject.index('#### name1')
      end
    end
  end
end
