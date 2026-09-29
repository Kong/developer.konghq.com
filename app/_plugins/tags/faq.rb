# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderFaq < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']
      keys = @param.split('.')
      faqs = if !@param.nil? && !@param.empty?
               keys.reduce(context) { |c, key| c[key] }
             else
               @page['faqs']
             end

      context.stack do
        context['faqs'] = faqs
        ComponentTemplates.fetch('faqs', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('faqs', Jekyll::RenderFaq)
