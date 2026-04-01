# frozen_string_literal: true

module Jekyll
  class EventGatewayPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      site.data['event_gateway_policies'] ||= {}
      Jekyll::EventGatewayPolicyPages::Generator.run(site)
    end
  end
end
