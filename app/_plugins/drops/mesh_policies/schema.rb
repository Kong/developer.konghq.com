# frozen_string_literal: true

module Jekyll
  module Drops
    module MeshPolicies
      class Schema < Liquid::Drop # rubocop:disable Style/Documentation
        def self.all(policy:)
          policy.releases.map do |release|
            new(release:, policy:)
          end
        end

        attr_reader :release

        def initialize(release:, policy:) # rubocop:disable Lint/MissingSuper
          @release = release
          @policy = policy
        end

        def as_json
          schema.as_json
        end

        private

        def schema
          @schema ||= SchemaFile.new(release:, type: @policy.type, name: @policy.name)
        end
      end
    end
  end
end
