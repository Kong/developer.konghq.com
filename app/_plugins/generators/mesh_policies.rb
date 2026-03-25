# frozen_string_literal: true

module Jekyll
  class MeshPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      current_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.source, '_mesh_policies/**/*'),
        File.join(site.config['mesh_policy_schemas_path'], '**/*')
      )

      if Utils::Incremental.enabled? && @cached_mtimes && @cached_pages && !Utils::Incremental.mtimes_changed?(current_mtimes, @cached_mtimes)
        site.pages.concat(@cached_pages)
        Utils::Incremental.skip_regeneration(site, @cached_pages)
        site.data['mesh_policies'] = @cached_mesh_policies
        Jekyll.logger.info 'IncrementalGen:', 'Skipped MeshPoliciesGenerator (sources unchanged)'
        return
      end

      site.data['mesh_policies'] ||= {}

      before = site.pages.size
      Jekyll::MeshPolicyPages::Generator.run(site)

      @cached_pages = site.pages[before..]
      @cached_mesh_policies = site.data['mesh_policies'].dup
      @cached_mtimes = current_mtimes
    end
  end
end
