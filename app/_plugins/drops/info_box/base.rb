# frozen_string_literal: true

module Jekyll
  module Drops
    module InfoBox
      class Base < Liquid::Drop
        MAPPINGS = {
          'plugin'           => 'Plugin',
          'plugin_reference' => 'Plugin',
          'entity_reference' => 'EntityReference',
          'tutorial'         => 'Tutorial'
        }

        def self.make_for(page:, site:)
          if page['collection'] == 'gateway_entities'
            klass = MAPPINGS['entity_reference']
          else
            klass = MAPPINGS[page['content_type']]
          end

          raise ArgumentError, "Unsupported info box type: #{page['content_type']}. Available types: #{MAPPINGS.keys.join(', ')}" unless klass

          Object.const_get("Jekyll::Drops::InfoBox::#{klass}").new(page:, site:)
        end

        def initialize(page:, site:)
          @page = page
          @site = site
        end

        def template_file
          raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
        end

        def products
          @products ||= begin
            products = @page.fetch('products', [])
            return [] if products.empty?

            @site.data['products'].values_at(*products)
          end
        end

        def tags
          @tags ||= begin
            tags = @page.fetch('tags', [])
            return [] if tags.empty?

            @site.data['tags'].select { |t| tags.include?(t['slug']) }
          end
        end

        def tools
          @tools ||= begin
            tools = @page.fetch('tools', [])
            return [] if tools.empty?

            @site.data['tools'].values_at(*tools)
          end
        end

        def tier
          @tier ||= begin
            tier = @page.fetch('tier', '')
            return if tier.empty?

            @site.data['tiers'].detect { |t| t['slug'] == tier }
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

        def works_on
          @works_on ||= @page.fetch('works_on', [])
        end
      end
    end
  end
end
