# frozen_string_literal: true

module Jekyll
  class RenderNewIn < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']

      raise ArgumentError, 'Missing required parameter `version` for {% new_in %} ' unless @param

      version = Gem::Version.correct?(@param) ? @param : context[@param]

      context.stack do
        context['version'] = version
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= if @page['output_format'] == 'markdown'
                      File.read(File.expand_path('app/_includes/components/new_in.md'))
                    else
                      File.read(File.expand_path('app/_includes/components/new_in.html'))
                    end
    end
  end
end

Liquid::Template.register_tag('new_in', Jekyll::RenderNewIn)
