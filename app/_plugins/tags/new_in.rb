# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderNewIn < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super
      @param = param.strip
    end

    def render(context)
      page = context.environments.first['page']

      raise ArgumentError, 'Missing required parameter `version` for {% new_in %}' if @param.empty?

      version = Gem::Version.correct?(@param) ? @param : context[@param]

      context.stack do
        context['version'] = version
        ComponentTemplates.fetch('new_in', page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('new_in', Jekyll::RenderNewIn)
