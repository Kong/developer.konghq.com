# frozen_string_literal: true

module Jekyll
  module Utils
    module Incremental
      DATA_FILES_GLOB = '_data/**/*.{yml,yaml,json}'

      # Only enable incremental caching in development.
      def self.enabled?
        Jekyll.env != 'production'
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

      # Shared per-item caching for generators that produce pages from subfolders.
      # Collects mtimes once for the parent folder (single glob), partitions by
      # subfolder prefix, and yields (slug, folder) for items needing regeneration.
      # Prunes stale cache entries for deleted items. Returns count of cache hits.
      def self.generate_items_with_cache(site, cache:, parent_folder:, data_key:) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        parent_path = File.join(site.source, parent_folder)
        all_mtimes = collect_mtimes("#{parent_path}/**/*")

        skipped = 0
        current_slugs = []

        Dir.glob("#{parent_path}/*/").each do |folder|
          slug = File.basename(folder)
          current_slugs << slug

          folder_mtimes = all_mtimes.select { |path, _| path.start_with?(folder) }
          cached = cache[slug]

          if cached && !mtimes_changed?(folder_mtimes, cached[:mtimes])
            site.pages.concat(cached[:pages])
            skip_regeneration(site, cached[:pages])
            site.data[data_key][slug] = cached[:data]
            skipped += 1
          else
            before = site.pages.size
            yield slug, folder
            new_pages = site.pages[before..]
            cache[slug] = { mtimes: folder_mtimes, pages: new_pages, data: site.data[data_key][slug] }
          end
        end

        # Prune stale cache entries for deleted items
        cache.select! { |slug, _| current_slugs.include?(slug) }

        skipped
      end
    end
  end
end
