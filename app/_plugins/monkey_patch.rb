# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module Tags
    class IncludeTag
      alias original_render render

      def render(context)
        site = context.registers[:site]
        include_path = File.join(site.includes_load_paths.first, Liquid::Template.parse(@file).render(context))
        previous = context.registers[:current_include_path]
        context.registers[:current_include_path] = include_path

        begin
          original_render(context)
        ensure
          context.registers[:current_include_path] = previous
        end
      end
    end

    class OptimizedIncludeTag < IncludeTag
      alias original_render render

      def render(context)
        site = context.registers[:site]
        include_path = File.join(site.includes_load_paths.first, Liquid::Template.parse(@file).render(context))
        previous = context.registers[:current_include_path]
        context.registers[:current_include_path] = include_path

        begin
          original_render(context)
        ensure
          context.registers[:current_include_path] = previous
        end
      end
    end
  end
end
