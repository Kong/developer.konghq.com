# frozen_string_literal: true

module Jekyll
  class EventGatewayPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    POLICIES_FOLDER = '_event_gateway_policies'

    def generate(site)
      site.data['event_gateway_policies'] ||= {}

      unless Utils::Incremental.enabled?
        Jekyll::EventGatewayPolicyPages::Generator.run(site)
        return
      end

      @policy_cache ||= {}
      generator = Jekyll::EventGatewayPolicyPages::Generator.new(site)
      skipped = Utils::Incremental.generate_items_with_cache(
        site, cache: @policy_cache, parent_folder: POLICIES_FOLDER, data_key: 'event_gateway_policies'
      ) do |slug, folder|
        policy = Jekyll::EventGatewayPolicyPages::Policy.new(folder:, slug:)
        generator.generate_pages(policy)
      end

      Jekyll.logger.info 'IncrementalGen:', "EventGatewayPoliciesGenerator: #{skipped} policies restored from cache" if skipped.positive?
    end
  end
end
