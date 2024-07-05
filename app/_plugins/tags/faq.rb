# frozen_string_literal: true

module Jekyll
  class RenderFaq < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']
      faqs = if !@param.nil? && !@param.empty?
                            @context['include']['config']
                          else
                            @page['faqs']
                          end

      Liquid::Template
        .parse(template)
        .render(
          { 'site' => @site.config, 'page' => @page, 'include' => { 'faqs' => faqs } },
          { registers: @context.registers, context: @context }
        )
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/faqs.html'))
    end
  end
end

Liquid::Template.register_tag('faqs', Jekyll::RenderFaq)
