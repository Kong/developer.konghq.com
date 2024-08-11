# frozen_string_literal: true

module Jekyll
  module PluginPages
    class Generator
      PLUGINS_FOLDER = '_kong_plugins'.freeze

      def self.run(site)
        Dir.glob(File.join(site.source, "#{PLUGINS_FOLDER}/*/")).each do |folder|
          slug = folder.gsub("#{site.source}/#{PLUGINS_FOLDER}/", '').chomp('/')

          Jekyll::PluginPages::Plugin.new(site:, folder:, slug:).generate_pages
        end
      end
    end
  end
end
