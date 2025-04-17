# frozen_string_literal: true

module Jekyll
  module KumaSpecific
    class CustomBlock < Liquid::Block # rubocop:disable Style/Documentation
      def initialize(tag_name, markup, options)
        super
        # Classes differs between Kuma and Kong docs, but they have the same
        # underlying meanings
        @class_name = {
          'tip' => 'info',
          'warning' => 'warning',
          'danger' => 'danger'
        }.fetch(tag_name, 'note')
      end

      def render(context)
        content = Kramdown::Document.new(super).to_html
        <<~HTML
          <blockquote class="#{@class_name}">
            #{content}
          </blockquote>
        HTML
      end
    end
  end
end

Liquid::Template.register_tag('tip', Jekyll::KumaSpecific::CustomBlock)
Liquid::Template.register_tag('warning', Jekyll::KumaSpecific::CustomBlock)
Liquid::Template.register_tag('danger', Jekyll::KumaSpecific::CustomBlock)
