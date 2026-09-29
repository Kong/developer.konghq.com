# frozen_string_literal: true

module Jekyll
  class AIGatewayPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    # This generator depends on the Kong Plugins pages,
    # so we need to run after the KongPluginsGenerator first to ensure the data is available.
    # Hence the file name is prefixed with "plugins_" to ensure it runs after the KongPluginsGenerator.
    priority :high

    def generate(site)
      site.data['ai_gateway_policies'] ||= {}
      Jekyll::AIGatewayPolicyPages::Generator.run(site)
    end
  end
end
