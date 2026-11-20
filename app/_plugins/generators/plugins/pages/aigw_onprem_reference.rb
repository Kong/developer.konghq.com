# frozen_string_literal: true

require_relative '../../../drops/plugins/aigw_policy_schema'
require_relative 'base'
require_relative 'reference'

module Jekyll
  module PluginPages
    module Pages
      class AIGatewayOnPremReference < Reference
        def self.url(plugin)
          "/plugins/#{plugin.slug}/ai-gateway/v2/on-prem/reference/"
        end

        def schema
          @schema ||= Drops::Plugins::AIGWPolicySchema.new(slug: @plugin.slug)
        end
        private :schema

        def versions_info
          {}
        end

        def data
          super.merge(
            'skip_versioner' => true,
            'aigw_onprem_url' => self.class.url(@plugin),
            'aigw_onprem_plugin_reference?' => true,
            'canonical?' => true,
            'canonical_url' => self.class.url(@plugin),
            'releases_dropdown' => Drops::ReleasesDropdown.new(
              base_url: Reference.url(@plugin),
              releases: @plugin.deduplicated_releases
            )
          )
        end
      end
    end
  end
end
