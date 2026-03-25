# frozen_string_literal: true

module Jekyll
  class EventGatewayPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      current_mtimes = Utils::Incremental.collect_mtimes(
        File.join(site.source, '_event_gateway_policies/**/*')
      )

      if Utils::Incremental.enabled? && @cached_mtimes && @cached_pages && !Utils::Incremental.mtimes_changed?(current_mtimes, @cached_mtimes)
        site.pages.concat(@cached_pages)
        Utils::Incremental.skip_regeneration(site, @cached_pages)
        site.data['event_gateway_policies'] = @cached_event_gateway_policies
        Jekyll.logger.info 'IncrementalGen:', 'Skipped EventGatewayPoliciesGenerator (sources unchanged)'
        return
      end

      site.data['event_gateway_policies'] ||= {}

      before = site.pages.size
      Jekyll::EventGatewayPolicyPages::Generator.run(site)

      @cached_pages = site.pages[before..]
      @cached_event_gateway_policies = site.data['event_gateway_policies'].dup
      @cached_mtimes = current_mtimes
    end
  end
end
