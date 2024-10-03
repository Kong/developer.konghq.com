# frozen_string_literal: true

module Jekyll
  class RenderPrereqs < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']

      if @page['prerequisites'].any?
        context.stack do
          context['prereqs'] = @page['prerequisites']
          Liquid::Template.parse(template).render(context)
        end
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/prereqs.html'))
    end
  end
end

Liquid::Template.register_tag('prereqs', Jekyll::RenderPrereqs)
