# frozen_string_literal: true

RSpec.describe Jekyll::ClosestHeading do
  let(:line_number) { nil }
  let(:page_content) { '' }
  let(:locals) { {} }
  let(:page) { { 'content' => page_content, 'path' => 'test.md' } }
  let(:context) { build_liquid_context(page: page, locals: locals) }

  subject(:heading) { described_class.new(page, line_number, context) }

  describe '#closest_heading' do
    context 'when line_number is nil' do
      it 'returns 2' do
        expect(heading.closest_heading).to eq(2)
      end
    end

    context 'when no heading appears above the line' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          some text
          {% tag %}
        MD
      end

      it 'returns nil' do
        expect(heading.closest_heading).to be_nil
      end
    end

    context 'with a heading immediately above' do
      let(:line_number) { 3 }
      let(:page_content) do
        <<~MD
          ## Section

          {% tag %}
        MD
      end

      it 'returns the level of that heading' do
        expect(heading.closest_heading).to eq(2)
      end
    end

    context 'with multiple headings above' do
      let(:line_number) { 5 }
      let(:page_content) do
        <<~MD
          # Top
          ## Section
          some text
          ### Sub
          {% tag %}
        MD
      end

      it 'returns the level of the nearest heading' do
        expect(heading.closest_heading).to eq(3)
      end
    end

    (1..6).each do |level|
      context "with an h#{level} heading above" do
        let(:line_number) { 2 }
        let(:page_content) { "#{'#' * level} Title\n{% tag %}\n" }

        it "returns #{level}" do
          expect(heading.closest_heading).to eq(level)
        end
      end
    end

    context 'with a line that starts with # but no space after' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          #NotAHeading
          {% tag %}
        MD
      end

      it 'does not treat it as a heading' do
        expect(heading.closest_heading).to be_nil
      end
    end

    context 'with an indented heading' do
      let(:line_number) { 2 }
      let(:page_content) { "  ## Indented\n{% tag %}\n" }

      it 'does not match — regex is anchored at line start' do
        expect(heading.closest_heading).to be_nil
      end
    end

    context 'with more than 6 hashes' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          ####### Too Many
          {% tag %}
        MD
      end

      it 'does not match' do
        expect(heading.closest_heading).to be_nil
      end
    end

    context 'with empty page content' do
      let(:line_number) { 1 }
      let(:page_content) { '' }

      it 'returns nil' do
        expect(heading.closest_heading).to be_nil
      end
    end
  end

  describe '#level' do
    context 'when prereqs is truthy in context' do
      let(:locals) { { 'prereqs' => true } }
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          # Top
          {% tag %}
        MD
      end

      it 'returns 4 regardless of headings' do
        expect(heading.level).to eq(4)
      end
    end

    context 'with a heading above' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          ## Section
          {% tag %}
        MD
      end

      it 'returns the heading level + 1' do
        expect(heading.level).to eq(3)
      end
    end

    context 'with no heading but heading_level in context' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          some text
          {% tag %}
        MD
      end
      let(:locals) { { 'heading_level' => 5 } }

      it 'falls back to heading_level + 1' do
        expect(heading.level).to eq(6)
      end
    end

    context 'with no heading but include.heading_level set' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          some text
          {% tag %}
        MD
      end
      let(:locals) { { 'include' => { 'heading_level' => 4 } } }

      it 'falls back to include.heading_level + 1' do
        expect(heading.level).to eq(5)
      end
    end

    context 'with no heading and no level in context' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          some text
          {% tag %}
        MD
      end

      it 'returns 3 (default 2 + 1)' do
        expect(heading.level).to eq(3)
      end
    end

    context 'when tab_id is set' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          ## Section
          {% tag %}
        MD
      end
      let(:locals) { { 'tab_id' => 'tab-1' } }

      it 'adds 1 more (closest + 2)' do
        expect(heading.level).to eq(4)
      end
    end

    context 'when line_number is nil' do
      it 'returns 3 (closest_heading returns 2, plus 1)' do
        expect(heading.level).to eq(3)
      end
    end

    context 'precedence: closest heading wins over heading_level' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          ## Section
          {% tag %}
        MD
      end
      let(:locals) { { 'heading_level' => 5 } }

      it 'uses the closest heading, ignoring heading_level' do
        expect(heading.level).to eq(3)
      end
    end

    context 'precedence: heading_level wins over include.heading_level' do
      let(:line_number) { 2 }
      let(:page_content) do
        <<~MD
          some text
          {% tag %}
        MD
      end
      let(:locals) do
        { 'heading_level' => 3, 'include' => { 'heading_level' => 5 } }
      end

      it 'prefers heading_level' do
        expect(heading.level).to eq(4)
      end
    end
  end

  describe 'when current_include_path is set in registers' do
    let(:include_path) { '/some/include.md' }
    let(:include_lines) do
      <<~MD.lines
        ### Inside include
        {% tag %}
      MD
    end
    let(:line_number) { 2 }

    before do
      context.registers[:current_include_path] = include_path
      allow(File).to receive(:readlines).with(include_path).and_return(include_lines)
    end

    it 'reads lines from the include file instead of page content' do
      expect(heading.closest_heading).to eq(3)
    end
  end
end
