# frozen_string_literal: true

module Jekyll
  class RenderPrereqs < Liquid::Tag
    def render(context)
      @context = context
      @page = context.environments.first['page']
      site = context.registers[:site]

      tools   = @page.fetch('tools', {})
      prereqs = @page.fetch('prereqs', {})

      prereqs_drop = Drops::Prereqs.new(prereqs:, tools:, site:)

      if prereqs_drop.any?
        context.stack do
          context['prereqs'] = prereqs_drop
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
