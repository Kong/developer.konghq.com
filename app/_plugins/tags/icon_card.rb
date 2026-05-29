# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderIconCard < Liquid::Tag
    def initialize(tag_name, markup, _tokens)
      super

      @params = {}
      markup.scan(/(\w+)\s*=\s*(?:["']([^"']+)["']|([\w.-]+))/) do |key, quoted, unquoted|
        @params[key] = { value: quoted || unquoted, literal: !quoted.nil? }
      end
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']

      context.stack do
        @params.each do |key, param|
          context[key] = if param[:literal]
                           param[:value]
                         else
                           context[param[:value]]
                         end
        end
        ComponentTemplates.fetch('icon_card', 'markdown', base: 'app/_includes/cards').render(context)
      end
    end

  end
end

Liquid::Template.register_tag('icon_card', Jekyll::RenderIconCard)
