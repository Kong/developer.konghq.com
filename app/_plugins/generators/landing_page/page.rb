# frozen_string_literal: true

module Jekyll
  module LandingPages
    class Page
      def initialize(site, file)
        @site = site
        @data = YAML.load_file(file)
        puts "CREATING A PAGE FOR #{@data['title']} at '#{output_path(file)}'"
      end

      private

      def output_path(file)
        file.sub(@site.source, @site.dest).sub(/\/_landing_pages\/(\w+)\.yaml$/, '/\1.html')
      end
    end
  end
end
