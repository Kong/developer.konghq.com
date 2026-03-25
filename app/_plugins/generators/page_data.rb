# frozen_string_literal: true

module Jekyll
  class PageDataGenerator < Generator # rubocop:disable Style/Documentation
    priority :lowest

    ENRICHMENT_KEYS = %w[
      edit_link breadcrumbs api_specs seo_noindex canonical? canonical_url
      search latest_release published all_docs_indices title_tag llm_title
      llm_metadata llm_frontmatter prerequisites prereqs navigation cleanup
    ].freeze

    def generate(site) # rubocop:disable Metrics/MethodLength
      incremental = Utils::Incremental.enabled?
      data_changed = true

      if incremental
        data_mtimes = Utils::Incremental.collect_mtimes(
          File.join(site.source, '_data/**/*.{yml,yaml,json}')
        )
        data_changed = @cached_data_mtimes.nil? || Utils::Incremental.mtimes_changed?(data_mtimes, @cached_data_mtimes)

        @enrichment_cache ||= {}
        @page_mtimes ||= {}
        @enrichment_cache.clear if data_changed
      end

      Data::Series.new(site:).process

      skipped = 0
      skipped += process_pages(site, data_changed)
      skipped += process_docs(site, data_changed)

      @cached_data_mtimes = data_mtimes if incremental

      Jekyll.logger.info 'IncrementalGen:', "PageDataGenerator: #{skipped} pages restored from cache" if skipped.positive?
    end

    def process_pages(site, data_changed) # rubocop:disable Metrics/AbcSize
      skipped = 0
      site.pages.each do |page|
        if !data_changed && restore_from_cache(site, page)
          skipped += 1
          next
        end

        enrich_page(site, page)
        cache_enrichment(site, page)
      end
      skipped
    end

    def process_docs(site, data_changed) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      skipped = 0
      site.documents.each do |page|
        if !data_changed && restore_from_cache(site, page)
          skipped += 1
          next
        end

        enrich_doc(site, page)
        cache_enrichment(site, page)
      end
      skipped
    end

    private

    def enrich_page(site, page)
      Data::EditLink::Base.new(site:, page:).process
      Data::Breadcrumbs.new(site:, page:).process
      Data::APISpecs.new(site:, page:).process
      Data::Seo.new(site:, page:).process
      Data::SearchTags::Base.make_for(site:, page:).process
      Data::MinVersion.new(site:, page:).process
      Data::AddAllDocIndices.new(site:, page:).process
      Data::TitleTag.new(site:, page:).process
      Data::LlmMetadata.new(site:, page:).process
    end

    def enrich_doc(site, page)
      Data::EditLink::Base.new(site:, page:).process
      Data::Prerequisites.new(site:, page:).process
      Data::Breadcrumbs.new(site:, page:).process
      Data::APISpecs.new(site:, page:).process
      Data::Seo.new(site:, page:).process
      Data::SearchTags::Base.make_for(site:, page:).process
      Data::MinVersion.new(site:, page:).process
      Data::AddAllDocIndices.new(site:, page:).process
      Data::TitleTag.new(site:, page:).process
      Data::LlmMetadata.new(site:, page:).process
    end

    def page_source_mtime(site, page)
      source_path = if page.respond_to?(:path) && File.exist?(page.path)
                      page.path
                    else
                      site.in_source_dir(page.relative_path)
                    end
      File.exist?(source_path) ? File.mtime(source_path) : nil
    end

    def restore_from_cache(site, page)
      cache_key = page.relative_path
      return false unless @enrichment_cache.key?(cache_key)

      current_mtime = page_source_mtime(site, page)
      return false if current_mtime != @page_mtimes[cache_key]

      page.data.merge!(@enrichment_cache[cache_key])
      true
    end

    def cache_enrichment(site, page)
      return unless @enrichment_cache

      cache_key = page.relative_path
      @page_mtimes[cache_key] = page_source_mtime(site, page)
      @enrichment_cache[cache_key] = page.data.slice(*ENRICHMENT_KEYS)
    end
  end
end
