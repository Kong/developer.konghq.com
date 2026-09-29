# frozen_string_literal: true

require_relative '../component_templates'

module Kramdown
  module Converter
    class Html # rubocop:disable Style/Documentation
      alias original_convert_codeblock convert_codeblock

      def convert_codeblock(el, indent)
        render_shiki(el, indent)
      end

      def render_shiki(el, _indent) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Naming/MethodParameterName
        language = extract_code_language!(el.attr) || 'text'
        data = data_attributes(el.attr)
        copy = copy?(el.attr)
        code = el.value
        id = SecureRandom.uuid

        snippet = CodeHighlighter.new.highlight(code, language, id)
        ::Jekyll::ComponentTemplates.fetch('syntax_highlighting', 'html', base: 'app/_includes').render(
          {
            'site' => site.site_payload['site'],
            'codeblock' => {
              'copy' => copy,
              'css_classes' => el.attr['class'],
              'collapsible' => el.attr.fetch('class', '').include?('collapsible'),
              'render_header' => !data['data-file'].nil?,
              'id' => id,
              'data' => data,
              'snippet' => snippet
            }
          }
        )
      end

      def site
        @site ||= Jekyll.sites.first
      end

      def copy?(attr)
        !attr.fetch('class', '').include?('no-copy-code')
      end

      def data_attributes(attr)
        @data_attributes = attr.each_with_object({}) do |(key, value), data|
          data[key] = value if key.start_with?('data-')
        end
      end
    end
  end
end
