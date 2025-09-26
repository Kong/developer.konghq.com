# frozen_string_literal: true

require_relative '../policies/base'

module Jekyll
  module EventGatewayPolicyPages
    class Policy # rubocop:disable Style/Documentation
      include Policies::Base
      include Policies::GeneratorBase

      def schema
        @schema ||= metadata.fetch('schema')
      end
    end
  end
end
