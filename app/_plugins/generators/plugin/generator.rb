# frozen_string_literal: true

module Jekyll
  module KongPlugin
    class Generator
      def self.run(site)
        all_tutorials = []
        Dir.glob(File.join(site.source, '_kong_plugins/**/*.md')).each do |file|
          plugin = Jekyll::KongPlugin::Page.new(site, file)
          site.pages << plugin
          all_tutorials << plugin
        end

        # Generate index page
        site.pages << Jekyll::KongPlugin::List.new(site, all_tutorials)
      end
    end
  end
end
