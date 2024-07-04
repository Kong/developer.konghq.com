# frozen_string_literal: true

module Jekyll
  class RenderRelatedResources < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']
      related_resources = if !@param.nil? && !@param.empty?
                            @context['include']['config']
                          else
                            @page['related_resources']
                          end

      Liquid::Template
        .parse(template)
        .render(
          { 'site' => @site.config, 'page' => @page, 'include' => { 'related_resources' => related_resources } },
          { registers: @context.registers, context: @context }
        )
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/related_resources.html'))
    end
  end
end

Liquid::Template.register_tag('related_resources', Jekyll::RenderRelatedResources)
