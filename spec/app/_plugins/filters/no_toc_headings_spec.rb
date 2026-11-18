# frozen_string_literal: true

RSpec.describe NoTocHeadingsFilter do
  let(:filter) { Class.new { include NoTocHeadingsFilter }.new }

  describe '#no_toc_headings' do
    describe 'heading levels' do
      (2..6).each do |level|
        it "adds the class to an h#{level} heading" do
          expect(filter.no_toc_headings("<h#{level}>Title</h#{level}>"))
            .to eq("<h#{level} class=\"no_toc\">Title</h#{level}>")
        end
      end

      it 'leaves an h1 heading alone' do
        expect(filter.no_toc_headings('<h1>Title</h1>')).to eq('<h1>Title</h1>')
      end
    end

    describe 'headings with attributes' do
      it 'keeps an existing id attribute' do
        expect(filter.no_toc_headings('<h3 id="x">Title</h3>'))
          .to eq('<h3 class="no_toc" id="x">Title</h3>')
      end

      it 'appends to an existing class attribute' do
        expect(filter.no_toc_headings('<h3 class="foo" id="x">Title</h3>'))
          .to eq('<h3 class="foo no_toc" id="x">Title</h3>')
      end

      it 'does not add the class twice' do
        expect(filter.no_toc_headings('<h3 class="no_toc" id="x">Title</h3>'))
          .to eq('<h3 class="no_toc" id="x">Title</h3>')
      end
    end

    describe 'multiple headings' do
      it 'adds the class to every heading in the input' do
        input = "<h2>One</h2>\n<p>Text</p>\n<h4 id=\"two\">Two</h4>"

        expect(filter.no_toc_headings(input))
          .to eq("<h2 class=\"no_toc\">One</h2>\n<p>Text</p>\n<h4 class=\"no_toc\" id=\"two\">Two</h4>")
      end
    end

    describe 'edge inputs' do
      it 'returns an empty string for nil' do
        expect(filter.no_toc_headings(nil)).to eq('')
      end

      it 'returns the input unchanged when it has no headings' do
        expect(filter.no_toc_headings('<p>Text</p>')).to eq('<p>Text</p>')
      end
    end
  end
end
