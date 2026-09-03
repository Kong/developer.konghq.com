# frozen_string_literal: true

module Kramdown
  module Converter
    class Html
      alias_method :orig_convert_a, :convert_a

      def convert_a(el, indent)
        href = el.attr['href']
        if href&.match?(/\Ahttps?:/) && !el.attr.key?('target')
          el.attr['target'] = '_blank'
          existing_rel = el.attr['rel']
          el.attr['rel'] = ['noopener', 'nofollow', 'noreferrer ', existing_rel]
                             .compact.reject(&:empty?).join(' ')
        end
        orig_convert_a(el, indent)
      end
    end
  end
end
