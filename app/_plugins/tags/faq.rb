# frozen_string_literal: true

require_relative '../monkey_patch'

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
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/faqs.md'))
      else
        File.read(File.expand_path('app/_includes/components/faqs.html'))
      end
    end
  end
end

Liquid::Template.register_tag('faqs', Jekyll::RenderFaq)
