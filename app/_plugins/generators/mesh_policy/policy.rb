# frozen_string_literal: true

require_relative '../policies/base'

module Jekyll
  module MeshPolicyPages
    class Policy # rubocop:disable Style/Documentation
      include Policies::Base
      include Policies::GeneratorBase

      def schema
        @schema ||= schemas.detect { |s| s.release == latest_release_in_range }
      end

      def schemas
        @schemas ||= Drops::MeshPolicies::Schema.all(policy: self)
      end

      def examples
        @examples ||= example_files.map do |file|
          Drops::PolicyConfigExample::Mesh.new(
            file: file,
            plugin: self
          )
        end.sort_by { |e| -e.weight } # rubocop:disable Style/MultilineBlockChain
      end
    end
  end
end
