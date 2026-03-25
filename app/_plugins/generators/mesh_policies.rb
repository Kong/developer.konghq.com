# frozen_string_literal: true

module Jekyll
  class MeshPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    POLICIES_FOLDER = '_mesh_policies'

    def generate(site) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      site.data['mesh_policies'] ||= {}

      unless Utils::Incremental.enabled?
        Jekyll::MeshPolicyPages::Generator.run(site)
        return
      end

      @policy_cache ||= {}
      schema_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.config['mesh_policy_schemas_path'], '**/*')
      )
      schemas_changed = @cached_schema_mtimes.nil? || Utils::Incremental.mtimes_changed?(schema_mtimes, @cached_schema_mtimes)
      @policy_cache.clear if schemas_changed

      skipped = 0
      generator = Jekyll::MeshPolicyPages::Generator.new(site)

      Dir.glob(File.join(site.source, "#{POLICIES_FOLDER}/*/")).each do |folder|
        slug = folder.gsub("#{site.source}/#{POLICIES_FOLDER}/", '').chomp('/')
        current_mtimes = Utils::Incremental.collect_mtimes("#{folder}**/*")
        cached = @policy_cache[slug]

        if cached && !Utils::Incremental.mtimes_changed?(current_mtimes, cached[:mtimes])
          site.pages.concat(cached[:pages])
          Utils::Incremental.skip_regeneration(site, cached[:pages])
          site.data['mesh_policies'][slug] = cached[:data]
          skipped += 1
        else
          before = site.pages.size
          policy = Jekyll::MeshPolicyPages::Policy.new(folder:, slug:)
          generator.generate_pages(policy)
          new_pages = site.pages[before..]
          @policy_cache[slug] = { mtimes: current_mtimes, pages: new_pages, data: site.data['mesh_policies'][slug] }
        end
      end

      @cached_schema_mtimes = schema_mtimes
      Jekyll.logger.info 'IncrementalGen:', "MeshPoliciesGenerator: #{skipped} policies restored from cache" if skipped.positive?
    end
  end
end
