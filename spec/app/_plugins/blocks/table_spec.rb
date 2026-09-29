# frozen_string_literal: true

RSpec.describe Jekyll::Table do
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
          {% table %}
          columns:
            - title: Name
              key: name
            - title: Value
              key: value
          rows:
            - name: foo
              value: 1
            - name: bar
              value: 2
          {% endtable %}
        LIQUID
      end

      it 'renders a table element' do
        expect(html).to have_css('table')
      end

      it 'renders a th element per column' do
        expect(html).to have_css('th', count: 2)
      end

      it 'renders the column titles' do
        expect(html).to have_css('thead tr th:nth-of-type(1)', text: 'Name')
        expect(html).to have_css('thead tr th:nth-of-type(2)', text: 'Value')

        first_row = html.find('tbody tr:nth-of-type(1)')
        expect(first_row).to have_css('td:nth-of-type(1)', text: 'foo')
        expect(first_row).to have_css('td:nth-of-type(2)', text: '1')

        second_row = html.find('tbody tr:nth-of-type(2)')
        expect(second_row).to have_css('td:nth-of-type(1)', text: 'bar')
        expect(second_row).to have_css('td:nth-of-type(2)', text: '2')
      end
    end

    context 'with a row containing code' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Code
              key: code
            - title: Message
              key: message
          rows:
            - code: E001
              message: An error
          {% endtable %}
        LIQUID
      end

      it 'wraps the code value in a <code> element' do
        expect(html).to have_css('td code', text: 'E001')
      end

      it 'sets the row id to the code value' do
        expect(html).to have_css('tr#E001')
      end
    end

    context 'with a row having both code and an explicit id' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Code
              key: code
          rows:
            - code: E001
              id: explicit-id
          {% endtable %}
        LIQUID
      end

      it 'preserves the explicit id' do
        expect(html).to have_css('tr#explicit-id')
        expect(html).to have_no_css('tr#E001')
      end
    end

    context 'with a true cell value' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Feature
              key: feature
            - title: Supported
              key: supported
          rows:
            - feature: foo
              supported: true
          {% endtable %}
        LIQUID
      end

      it 'renders the icon_true include' do
        expect(html).to have_css('span.sr-only', text: 'Supported')
      end
    end

    context 'with a false cell value' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Feature
              key: feature
            - title: Supported
              key: supported
          rows:
            - feature: foo
              supported: false
          {% endtable %}
        LIQUID
      end

      it 'renders the icon_false include' do
        expect(html).to have_css('span.sr-only', text: 'Not supported')
      end
    end

    context 'with vertical_align config' do
      let(:template) do
        <<~LIQUID
          {% table %}
          vertical_align: middle
          columns:
            - title: Name
              key: name
          rows:
            - name: foo
          {% endtable %}
        LIQUID
      end

      it 'applies the vertical-align style on td' do
        expect(html).to have_css('td[style*="vertical-align: middle"]')
      end
    end

    context 'without vertical_align' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Name
              key: name
          rows:
            - name: foo
          {% endtable %}
        LIQUID
      end

      it 'defaults to top alignment' do
        expect(html).to have_css('td[style*="vertical-align: top"]')
      end
    end
  end

  describe 'rendering (markdown output)' do
    let(:format) { 'markdown' }

    context 'with simple data' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Name
              key: name
            - title: Value
              key: value
          rows:
            - name: foo
              value: 1
            - name: bar
              value: 2
          {% endtable %}
        LIQUID
      end

      it 'renders the first column value as a heading' do
        expect(subject).to include('### foo')
        expect(subject).to include('### bar')
      end

      it 'renders the other columns as key:value' do
        expect(subject).to include('Value: 1')
        expect(subject).to include('Value: 2')
      end

      it 'renders each row title followed by its content, in row order' do
        expect(subject).to eq(<<~MD + "\n")
          ### foo
          Value: 1

          ### bar
          Value: 2

        MD
      end
    end

    context 'with multiple non-title columns' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Name
              key: name
            - title: Value
              key: value
            - title: Status
              key: status
          rows:
            - name: foo
              value: 1
              status: ok
            - name: bar
              value: 2
              status: pending
          {% endtable %}
        LIQUID
      end

      it 'renders each row title followed by its content lines in column order' do
        expect(subject).to eq(<<~MD + "\n")
          ### foo
          Value: 1
          Status: ok

          ### bar
          Value: 2
          Status: pending

        MD
      end
    end

    context 'with boolean cell values' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Feature
              key: feature
            - title: Supported
              key: supported
          rows:
            - feature: foo
              supported: true
            - feature: bar
              supported: false
          {% endtable %}
        LIQUID
      end

      it 'renders true as "true"' do
        expect(subject).to include('Supported: true')
      end

      it 'renders false as "false"' do
        expect(subject).to include('Supported: false')
      end
    end

    context 'with a multi-line cell value' do
      let(:template) do
        <<~LIQUID
          {% table %}
          columns:
            - title: Name
              key: name
            - title: Description
              key: description
          rows:
            - name: foo
              description: |
                first line
                second line
          {% endtable %}
        LIQUID
      end

      it 'uses the YAML pipe block syntax for the value' do
        expect(subject).to include("Description: |\n  first line\n  second line")
      end
    end
  end

  describe 'YAML error handling' do
    let(:template) do
      <<~LIQUID
        {% table %}
        columns: [
        {% endtable %}
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
