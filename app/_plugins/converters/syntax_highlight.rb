# frozen_string_literal: true

require 'kramdown/parser/kramdown'
require 'kramdown/converter/html'

module Kramdown
  module Converter
    class Html
      alias original_convert_codeblock convert_codeblock

      def convert_codeblock(el, _indent) # rubocop:disable Naming/MethodParameterName,Metrics/MethodLength
        attr = el.attr.dup
        data = data_attributes(attr)
        copy = copy?(attr)

        Liquid::Template.parse(template).render(
          {
            'codeblock' => {
              'copy' => copy,
              'data' => data, 'lang' => lang(attr), 'code' => escape_html(el.value),
              'css_classes' => attr['class'],
              'render_header' => !data['data-file'].nil?,
              'id' => SecureRandom.uuid
            }
          },
          context
        )
      end

      def data_attributes(attr)
        @data_attributes = attr.each_with_object({}) do |(key, value), data|
          data[key] = value if key.start_with?('data-')
        end
      end

      def lang(attr)
        extract_code_language!(attr) || 'plaintext'
      end

      def copy?(attr)
        !attr.fetch('class', '').include?('no-copy-code')
      end

      def site
        @site ||= Jekyll.sites.first
      end

      def context
        @context = Liquid::Context.new(site, {}, {})
      end

      def template
        @template ||= File.read(File.expand_path('app/_includes/syntax_highlighting.html'))
      end
    end
  end
end
