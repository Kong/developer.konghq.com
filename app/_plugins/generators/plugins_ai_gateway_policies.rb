# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class AIGatewayPoliciesGenerator < OrderedGenerator # rubocop:disable Style/Documentation
    # This generator depends on the Kong Plugins pages,
    # so we need to run after the KongPluginsGenerator first to ensure the data is available.
    # Hence the file name is prefixed with "plugins_" to ensure it runs after the KongPluginsGenerator.
    def generate(site)
      site.data['ai_gateway_policies'] ||= {}
      Jekyll::AIGatewayPolicyPages::Generator.run(site)
    end
  end
end
