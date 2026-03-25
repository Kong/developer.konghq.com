# frozen_string_literal: true

module Jekyll
  module Utils
    module Incremental
      # Only enable incremental caching in development.
      def self.enabled?
        ENV['JEKYLL_ENV'] != 'production'
      end

      # Collect mtimes for all files matching the given glob patterns.
      # Returns a hash of { absolute_path => mtime }.
      def self.collect_mtimes(*patterns)
        mtimes = {}
        patterns.each do |pattern|
          Dir.glob(pattern).each do |file|
            mtimes[file] = File.mtime(file)
          end
        end
        mtimes
      end

      # Returns true if the current mtimes differ from the cached mtimes
      # (file added, removed, or modified).
      def self.mtimes_changed?(current, cached)
        return true if current.size != cached.size

        current.any? { |path, mtime| cached[path] != mtime }
      end

      # Tell Jekyll's Regenerator to skip rendering/writing for these pages.
      # Without this, restored pages are treated as "new" and fully re-rendered.
      def self.skip_regeneration(site, pages)
        pages.each do |page|
          source_path = site.in_source_dir(page.relative_path)
          site.regenerator.cache[source_path] = false
        end
      end
    end
  end
end
