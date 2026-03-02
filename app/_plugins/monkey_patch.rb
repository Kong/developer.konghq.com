# frozen_string_literal: true

require 'jekyll'
require 'jekyll-include-cache'

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

module JekyllIncludeCache
  # Monkey-patch jekyll-include-cache include_cached tag so that it takes into account the
  # page output format (e.g. markdown vs html) when caching includes.
  class Tag
    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      site = context.registers[:site]
      page = context.registers[:page]
      path = path(context)

      params = @params ? parse_params(context) : {}
      params.merge!('output_format' => page['output_format'] || site.config['output_format'])

      key = key(path, params)
      return unless path

      if JekyllIncludeCache.cache.key?(key)
        Jekyll.logger.debug 'Include cache hit', path
        JekyllIncludeCache.cache[key]
      else
        Jekyll.logger.debug 'Include cache miss:', path
        JekyllIncludeCache.cache[key] = super
      end
    end
  end
end
