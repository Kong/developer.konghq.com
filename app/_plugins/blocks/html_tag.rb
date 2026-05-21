# frozen_string_literal: true

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
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/html_tag.md'))
      else
        File.read(File.expand_path('app/_includes/components/html_tag.html'))
      end
    end
  end
end

Liquid::Template.register_tag('html_tag', Jekyll::HtmlTag)
