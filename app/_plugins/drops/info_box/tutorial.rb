# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class Tutorial < Base
        def plugins
          @plugins ||= begin
            plugins = @page.fetch('plugins', [])

            if plugins.any?
              @site.collections['kong_plugins'].docs.select do |d|
                plugins.include?(d.data['slug'])
              end
            else
              plugins
            end
          end
        end

        def entities
          @entities ||= begin
            entities = @page.fetch('entities', [])

            if entities.any?
              @site.collections['gateway_entities'].docs.select do |d|
                entities.include?(d.data['slug'])
              end
            else
              entities
            end
          end
        end

        def products
          @products ||= @page.fetch('products', []).map do |product|
            @site.data['products'][product]
          end
        end

        def tags
          @tags ||= @page.fetch('tags', []).map do |tag|
            @site.data['tags'][tag]
          end
        end

        def tools
          @tools ||= @page.fetch('tools', []).map do |tool|
            # TODO:
            # We need to have a collection of tools pages accessible, so we can pull the urls + extra metadata from the actual page.
            # We can't use a Collection because these pages are generated with yaml.
            # We could have a specific folder for them, use a generator for generating the pages
            # and do something like @site.data['tools'] << page in it, and get rid of the tools.yml
            #
            # This same logic applies to product pages and plugins too
            @site.data['tools'][tool].merge('url' => "/#{tool}/")
          end
        end

        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/tutorial.html')
        end
      end
    end
  end
end
