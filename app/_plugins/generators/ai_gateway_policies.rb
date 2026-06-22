# frozen_string_literal: true

module Jekyll
  class AIGatewayPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    # This generator depends on the Kong Plugins pages,
    # so we need to run after the KongPluginsGenerator first to ensure the data is available.
    priority :normal

    def generate(site)
      site.data['ai_gateway_policies'] ||= {}
      Jekyll::AIGatewayPolicyPages::Generator.run(site)
    end
  end
end
