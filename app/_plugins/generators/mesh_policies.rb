# frozen_string_literal: true

module Jekyll
  class MeshPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    POLICIES_FOLDER = '_mesh_policies'

    def generate(site)
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

      generator = Jekyll::MeshPolicyPages::Generator.new(site)
      skipped = Utils::Incremental.generate_items_with_cache(
        site, cache: @policy_cache, parent_folder: POLICIES_FOLDER, data_key: 'mesh_policies'
      ) do |slug, folder|
        policy = Jekyll::MeshPolicyPages::Policy.new(folder:, slug:)
        generator.generate_pages(policy)
      end

      @cached_schema_mtimes = schema_mtimes
      Jekyll.logger.info 'IncrementalGen:', "MeshPoliciesGenerator: #{skipped} policies restored from cache" if skipped.positive?
    end
  end
end
