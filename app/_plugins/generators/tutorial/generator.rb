# frozen_string_literal: true

module Jekyll
  module Tutorial
    class Generator
      def self.run(site)
        Dir.glob(File.join(site.source, '_tutorials/**/*.md')).each do |file|
          site.pages << Jekyll::Tutorial::Page.new(site, file)
        end
      end
    end
  end
end
