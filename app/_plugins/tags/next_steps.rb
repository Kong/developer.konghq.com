# frozen_string_literal: true

require_relative '../monkey_patch'

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

      set_icons(next_steps['items'])

      context.stack do
        context['next_steps'] = next_steps
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    def set_icons(next_steps)
      next_steps.map do |step|
        LinkIconAssigner.new(step).process
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/next_steps.md'))
      else
        File.read(File.expand_path('app/_includes/components/next_steps.html'))
      end
    end
  end
end

Liquid::Template.register_tag('next_steps', Jekyll::RenderNextSteps)
