# frozen_string_literal: true

require 'open3'
require 'json'

module Jekyll
  class ShikiHighlighter # rubocop:disable Style/Documentation
    def self.highlight(code, language, id)
      command = ['node', 'app/_plugins/converters/shiki-bridge.js', language, id]

      stdout, stderr, status = Open3.capture3(*command, stdin_data: code)

      raise stderr.to_s if status != 0

      stdout
    end
  end
end

# Hook into Kramdown
module Kramdown
  module Converter
    class Html # rubocop:disable Style/Documentation
      alias original_convert_codeblock convert_codeblock

      def convert_codeblock(el, indent)
        if %w[production preview].include?(Jekyll.env)
          render_shiki(el, indent)
        else
          original_convert_codeblock(el, indent)
        end
      end

      def render_shiki(el, _indent) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Naming/MethodParameterName
        language = extract_code_language!(el.attr) || 'text'
        data = data_attributes(el.attr)
        copy = copy?(el.attr)
        code = el.value
        id = SecureRandom.uuid

        snippet = Jekyll::ShikiHighlighter.highlight(code, language, id)
        Liquid::Template.parse(template).render(
          {
            'codeblock' => {
              'copy' => copy,
              'css_classes' => el.attr['class'],
              'render_header' => !data['data-file'].nil?,
              'id' => id,
              'snippet' => snippet
            }
          },
          context
        )
      end

      def template
        @template ||= File.read(File.expand_path('app/_includes/syntax_highlighting.html'))
      end

      def context
        @context = Liquid::Context.new(site, {}, {})
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
