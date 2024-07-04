# frozen_string_literal: true

module Jekyll
  module KongEntity
    class Generator
      def self.run(site)
        all_entities = []
        Dir.glob(File.join(site.source, '_kong_entities/**/*.md')).each do |file|
          entity = Jekyll::KongEntity::Page.new(site, file)
          site.pages << entity
          all_entities << entity
        end

        # Generate index page
        site.pages << Jekyll::KongEntity::List.new(site, all_entities)
      end
    end
  end
end
