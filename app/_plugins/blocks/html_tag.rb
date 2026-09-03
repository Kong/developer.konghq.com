# frozen_string_literal: true

require_relative '../component_templates'

module Jekyll
  class HtmlTag < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @attributes = {}

      markup.scan(/(\w+)\s*=\s*(?:"([^"]*)"|'([^']*)')/) do |key, double_val, single_val|
        @attributes[key] = double_val || single_val
      end
    end

    def render(context)
      @page = context.environments.first['page']

      contents = super

      context.stack do
        context['include'] = {
          'type' => @attributes['type'],
          'css_classes' => @attributes['css_classes'],
          'content' => contents
        }
        ComponentTemplates.fetch('html_tag', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('html_tag', Jekyll::HtmlTag)
