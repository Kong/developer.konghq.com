# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module InfoBox
      class Tutorial < Base
        def plugins
          @plugins ||= begin
            plugins = @page.fetch('plugins', [])
            return [] if plugins.empty?

            @site.data['kong_plugins'].values_at(*plugins)
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

        def min_versions
          @min_versions ||= begin
            min_versions = @page.fetch('min_version', {})

            min_versions.map do |product, version|
              { 'product' => @site.data['products'][product]['name'], 'version' => version }
            end
          end
        end

        def template_file
          @template_file ||= File.expand_path('app/_includes/components/info_box/tutorial.html')
        end
      end
    end
  end
end
