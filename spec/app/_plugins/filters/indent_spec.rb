# frozen_string_literal: true

RSpec.describe IndentFilter do
  let(:filter) { Class.new { include IndentFilter }.new }

  describe '#indent' do
    describe 'space count' do
      it 'uses 3 spaces by default' do
        expect(filter.indent('hello')).to eq('   hello')
      end

      it 'accepts a custom integer count' do
        expect(filter.indent('hello', 2)).to eq('  hello')
      end

      it 'accepts a string and converts to integer' do
        expect(filter.indent('hello', '4')).to eq('    hello')
      end

      it 'returns input unchanged when count is 0' do
        expect(filter.indent('hello', 0)).to eq('hello')
      end
    end

    describe 'line handling' do
      it 'prepends a single line' do
        expect(filter.indent('hello', 2)).to eq('  hello')
      end

      it 'prepends every line of a multi-line input' do
        expect(filter.indent("a\nb\nc", 2)).to eq("  a\n  b\n  c")
      end
    end

    describe 'edge inputs' do
      it 'returns an empty string for empty input' do
        expect(filter.indent('', 2)).to eq('')
      end

      it 'returns an empty string for nil' do
        expect(filter.indent(nil, 2)).to eq('')
      end

      it 'calls to_s on non-string input' do
        expect(filter.indent(123, 2)).to eq('  123')
      end
    end

    describe '</code> handling' do
      it 'strips the newline immediately before </code>' do
        expect(filter.indent("foo\n</code>", 2)).to eq('  foo</code>')
      end

      it 'leaves </code> alone when not preceded by a newline' do
        expect(filter.indent('foo</code>bar', 2)).to eq('  foo</code>bar')
      end

      it 'only strips the newline immediately before </code>, not earlier ones' do
        expect(filter.indent("a\nb\nc\n</code>", 2)).to eq("  a\n  b\n  c</code>")
      end
    end
  end
end
