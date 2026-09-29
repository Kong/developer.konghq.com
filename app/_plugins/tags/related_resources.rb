# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

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

      # Check if it's using the convenience syntax, or the full syntax
      # If it's using convenience syntax, default to list style
      if related_resources.is_a?(Array)
        related_resources = {
          'layout' => {
            'style' => 'list'
          },
          'items' => related_resources
        }
      end

      set_icons(related_resources['items'])

      context.stack do
        context['related_resources'] = related_resources
        ComponentTemplates.fetch('related_resources', @page['output_format']).render(context)
      end
    end

    private

    def set_icons(related_resources)
      related_resources.map do |resource|
        LinkIconAssigner.new(resource).process
      end
    end
  end
end

Liquid::Template.register_tag('related_resources', Jekyll::RenderRelatedResources)
