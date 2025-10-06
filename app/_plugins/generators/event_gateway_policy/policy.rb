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

      def policy_target
        @policy_target ||= metadata.fetch('policy_target')
      end

      def examples
        @examples ||= example_files.map do |file|
          Drops::PolicyConfigExample::EventGateway.new(
            file: file,
            plugin: self
          )
        end.sort_by { |e| -e.weight } # rubocop:disable Style/MultilineBlockChain
      end

      def phases
        @phases ||= site.data.dig('entity_examples', 'config', 'phases').keys & metadata.fetch('phases', [])
      end
    end
  end
end
