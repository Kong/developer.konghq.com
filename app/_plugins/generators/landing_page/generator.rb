# frozen_string_literal: true

module Jekyll
  module LandingPages
    class Generator
      def self.run(site)
        Dir.glob(File.join(site.source, '_landing_pages/*.yaml')).each do |file|
          Jekyll::LandingPages::Page.new(site, file)
        end
      end
    end
  end
end
