# frozen_string_literal: true

module Jekyll
  class RenderRelatedResources < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']
      keys = @param.split('.')
      related_resources = if !@param.nil? && !@param.empty?
                            keys.reduce(context) { |c, key| c[key] }
                          else
                            @page['related_resources']
                          end

      @context.environments.unshift('related_resources' => related_resources)

      rendered_content = Liquid::Template.parse(template).render(@context)

      @context.environments.shift

      rendered_content
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/related_resources.html'))
    end
  end
end

Liquid::Template.register_tag('related_resources', Jekyll::RenderRelatedResources)
