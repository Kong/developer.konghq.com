# frozen_string_literal: true

RSpec.describe Jekyll::IncludeSVGTag do
  let(:page) { {} }
  let(:locals) { {} }
  let(:svg_path) { '/assets/test.svg' }
  let(:svg_content) do
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M0 0h24v24z"/></svg>'
  end
  let(:full_path) { File.join(JekyllSite.instance.source, svg_path) }

  subject { render_liquid(template, page:, locals:) }

  let(:html) { Capybara::Node::Simple.new(subject) }

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist?).with(full_path).and_return(true)
    allow(File).to receive(:read).with(full_path).and_return(svg_content)
  end

  describe 'basic rendering' do
    let(:template) { "{% include_svg '#{svg_path}' %}" }

    it 'includes the SVG content' do
      expect(html).to have_css('svg path')
    end
  end

  describe 'resolving the file path' do
    context 'from a quoted string literal' do
      let(:template) { "{% include_svg '#{svg_path}' %}" }

      it 'reads the file at site source + path' do
        expect(html).to have_css('svg path')
      end
    end

    context 'from a context variable' do
      let(:locals) { { 'icon' => svg_path } }
      let(:template) { '{% include_svg icon %}' }

      it 'resolves the variable to the path' do
        expect(html).to have_css('svg path')
      end
    end
  end

  describe 'width and height' do
    let(:template) { %({% include_svg '#{svg_path}' width="100" height="50" %}) }

    it 'applies both attributes' do
      expect(html).to have_css('svg[width="100"][height="50"]')
    end
  end

  describe 'allowed attributes' do
    {
      'role'      => 'img',
      'class'     => 'icon-foo',
      'focusable' => 'false',
      'id'        => 'my-icon'
    }.each do |attr, value|
      context "with #{attr}" do
        let(:template) { %({% include_svg '#{svg_path}' #{attr}="#{value}" %}) }

        it "applies the #{attr} attribute" do
          expect(html).to have_css(%(svg[#{attr}="#{value}"]))
        end
      end
    end
  end

  describe 'aria-* attributes' do
    %w[aria-label aria-hidden aria-labelledby aria-describedby].each do |attr|
      context "with #{attr}" do
        let(:template) { %({% include_svg '#{svg_path}' #{attr}="value" %}) }

        it "applies the #{attr} attribute" do
          expect(html).to have_css(%(svg[#{attr}="value"]))
        end
      end
    end
  end

  describe 'multiple options combined' do
    let(:template) do
      %({% include_svg '#{svg_path}' width="64" height="64" class="icon" role="img" id="my-svg" aria-label="search" focusable="false" %})
    end

    it 'applies all the specified attributes' do
      expect(html).to have_css(
        'svg[width="64"][height="64"][class="icon"][role="img"][id="my-svg"][aria-label="search"][focusable="false"]'
      )
    end
  end

  describe 'attribute value formats' do
    context 'with single quotes' do
      let(:template) { %({% include_svg '#{svg_path}' class='single-quoted' %}) }

      it 'strips the quotes' do
        expect(html).to have_css('svg[class="single-quoted"]')
      end
    end
  end

  describe 'source SVG attributes' do
    let(:svg_content) do
      %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" class="orig" width="10" height="10"><path d="M0 0h24v24z"/></svg>)
    end

    context 'overriding class' do
      let(:template) { %({% include_svg '#{svg_path}' class="overridden" %}) }

      it 'overrides the existing class attribute' do
        expect(html).to have_css('svg[class="overridden"]')
      end
    end

    context 'overriding width and height' do
      let(:template) { %({% include_svg '#{svg_path}' width="64" height="32" %}) }

      it 'overrides the existing width and height attributes' do
        expect(html).to have_css('svg[width="64"][height="32"]')
      end
    end

    context 'preserving unrelated attributes' do
      let(:template) { %({% include_svg '#{svg_path}' width="64" height="32" %}) }

      it 'preserves the source viewBox' do
        expect(html).to have_css('svg[viewbox="0 0 24 24"]')
      end
    end
  end

  describe 'missing file' do
    let(:template) { "{% include_svg '/assets/does-not-exist.svg' %}" }

    it 'raises ArgumentError including the file path' do
      expect { subject }.to raise_error(ArgumentError, %r{SVG file not found.*/assets/does-not-exist\.svg})
    end
  end
end
