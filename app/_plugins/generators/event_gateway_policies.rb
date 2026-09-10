# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class EventGatewayPoliciesGenerator < OrderedGenerator # rubocop:disable Style/Documentation
    def generate(site)
      site.data['event_gateway_policies'] ||= {}
      Jekyll::EventGatewayPolicyPages::Generator.run(site)
    end
  end
end
