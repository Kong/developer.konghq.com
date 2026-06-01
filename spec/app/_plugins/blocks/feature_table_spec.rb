# frozen_string_literal: true

RSpec.describe Jekyll::FeatureTable do
  let(:format) { 'html' }
  let(:page) { { 'output_format' => format, 'path' => 'test.md', 'content' => '' } }
  let(:locals) { {} }

  subject { render_liquid(template, page: page, locals: locals) }

  let(:html) { Capybara::Node::Simple.new(subject) }

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    %w[/assets/icons/check.svg /assets/icons/close.svg].each do |path|
      full = File.join(JekyllSite.instance.source, path)
      allow(File).to receive(:exist?).with(full).and_return(true)
      allow(File).to receive(:read).with(full).and_return('<svg xmlns="http://www.w3.org/2000/svg"/>')
    end
  end

  describe 'rendering (html output)' do
    context 'with simple data' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Plan A
              key: plan_a
            - title: Plan B
              key: plan_b
          features:
            - title: Feature One
              plan_a: true
              plan_b: false
            - title: Feature Two
              plan_a: false
              plan_b: true
          {% endfeature_table %}
        LIQUID
      end

      it 'renders a table element' do
        expect(html).to have_css('table')
      end

      it 'renders a th per column plus the row title column' do
        expect(html).to have_css('th', count: 3)
      end

      it 'renders the column titles' do
        expect(html).to have_css('thead tr th:nth-of-type(2)', text: 'Plan A')
        expect(html).to have_css('thead tr th:nth-of-type(3)', text: 'Plan B')

        first_row = html.find("tbody tr:nth-of-type(1)")
        expect(first_row).to have_css('td:nth-of-type(1)', text: 'Feature One')
        expect(first_row).to have_css('td:nth-of-type(2)', text: 'Supported')
        expect(first_row).to have_css('td:nth-of-type(3)', text: 'Not supported')

        second_row = html.find("tbody tr:nth-of-type(2)")
        expect(second_row).to have_css('td:nth-of-type(1)', text: 'Feature Two')
        expect(second_row).to have_css('td:nth-of-type(2)', text: 'Not supported')
        expect(second_row).to have_css('td:nth-of-type(3)', text: 'Supported')
      end
    end

    context 'with item_title' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          item_title: Feature
          columns:
            - title: Plan A
              key: plan_a
          features:
            - title: Feature One
              plan_a: true
          {% endfeature_table %}
        LIQUID
      end

      it 'renders the item_title as the first column header' do
        expect(html).to have_css('th', text: 'Feature')
      end
    end

    context 'with a true cell value' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Plan A
              key: plan_a
          features:
            - title: Feature One
              plan_a: true
          {% endfeature_table %}
        LIQUID
      end

      it 'renders the icon_true include' do
        expect(html).to have_css('span.sr-only', text: 'Supported')
      end
    end

    context 'with a false cell value' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Plan A
              key: plan_a
          features:
            - title: Feature One
              plan_a: false
          {% endfeature_table %}
        LIQUID
      end

      it 'renders the icon_false include' do
        expect(html).to have_css('span.sr-only', text: 'Not supported')
      end
    end

    context 'with a row url' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Plan A
              key: plan_a
          features:
            - title: Feature One
              url: /some/path
              plan_a: true
          {% endfeature_table %}
        LIQUID
      end

      it 'renders the row title as a link' do
        expect(html).to have_css('td a[href="/some/path"]', text: 'Feature One')
      end
    end

    context 'with a row subtitle' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Plan A
              key: plan_a
          features:
            - title: Feature One
              subtitle: A subtitle
              plan_a: true
          {% endfeature_table %}
        LIQUID
      end

      it 'renders the subtitle' do
        expect(html).to have_css('span.text-secondary', text: 'A subtitle')
      end
    end
  end

  describe 'rendering (markdown output)' do
    let(:format) { 'markdown' }

    context 'with simple data' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Plan A
              key: plan_a
            - title: Plan B
              key: plan_b
          features:
            - title: Feature One
              plan_a: true
              plan_b: false
            - title: Feature Two
              plan_a: false
              plan_b: true
          {% endfeature_table %}
        LIQUID
      end

      it 'renders each row title as a heading' do
        expect(subject).to include('### Feature One')
        expect(subject).to include('### Feature Two')
      end

      it 'renders column values as key-value pairs' do
        expect(subject).to include('Plan A: Supported')
        expect(subject).to include('Plan B: Not Supported')
      end

      it 'renders each row followed by its column values, in row order' do
        expect(subject).to eq("\n" + <<~MD + "\n")
          ### Feature One
          Plan A: Supported
          Plan B: Not Supported

          ### Feature Two
          Plan A: Not Supported
          Plan B: Supported

        MD
      end
    end

    context 'with item_title' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          item_title: Feature
          columns:
            - title: Plan A
              key: plan_a
          features:
            - title: Feature One
              plan_a: true
          {% endfeature_table %}
        LIQUID
      end

      it 'prefixes the row heading with item_title' do
        expect(subject).to include('### Feature: Feature One')
      end
    end

    context 'with string cell values' do
      let(:template) do
        <<~LIQUID
          {% feature_table %}
          columns:
            - title: Notes
              key: notes
          features:
            - title: Feature One
              notes: some text
            - title: Feature Two
              notes: other text
          {% endfeature_table %}
        LIQUID
      end

      it 'renders each row title followed by its column value, in row order' do
        expect(subject).to eq("\n" + <<~MD + "\n")
          ### Feature One
          Notes: some text

          ### Feature Two
          Notes: other text

        MD
      end
    end
  end

  describe 'YAML error handling' do
    let(:template) do
      <<~LIQUID
        {% feature_table %}
        columns: [
        {% endfeature_table %}
      LIQUID
    end

    it 'raises ArgumentError mentioning the page path' do
      expect { subject }.to raise_error(ArgumentError, /test\.md/)
    end

    it 'mentions that the yaml is malformed' do
      expect { subject }.to raise_error(ArgumentError, /malformed yaml/)
    end

    it 'includes line-numbered yaml in the error' do
      expect { subject }.to raise_error(ArgumentError, /0: columns: \[/)
    end
  end
end
