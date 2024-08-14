# frozen_string_literal: true

module Jekyll
  class RenderNextSteps < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = @context.environments.first['page']
      keys = @param.split('.')
      next_steps = if !@param.nil? && !@param.empty?
                     keys.reduce(context) { |c, key| c[key] }
                   else
                     @page['next_steps']
                   end

      # Check if it's using the convenience syntax, or the full syntax
      # If it's using convenience syntax, default to list style
      if next_steps.is_a?(Array)
        next_steps = {
          'layout' => {
            'style' => 'list'
          },
          'items' => next_steps
        }
      end

      context.stack do
        context['next_steps'] = next_steps
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/next_steps.html'))
    end
  end
end

Liquid::Template.register_tag('next_steps', Jekyll::RenderNextSteps)
