# frozen_string_literal: true

module Jekyll
  module Tutorial
    class Generator
      def self.run(site)
        all_tutorials = []
        Dir.glob(File.join(site.source, '_tutorials/**/*.md')).each do |file|
          tutorial = Jekyll::Tutorial::Page.new(site, file)
          site.pages << tutorial
          all_tutorials << tutorial
        end

        # Generate index page
        site.pages << Jekyll::Tutorial::List.new(site, all_tutorials)
      end
    end
  end
end
