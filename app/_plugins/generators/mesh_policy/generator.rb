# frozen_string_literal: true

require_relative '../policies/generator'
require_relative '../policies/generator_base'

module Jekyll
  module MeshPolicyPages
    class Generator # rubocop:disable Style/Documentation
      include Policies::Generator
      include Policies::GeneratorBase

      def self.policies_folder
        '_mesh_policies'
      end

      def key
        @key ||= 'mesh_policies'
      end

      def skip?
        site.config.dig('skip', 'mesh_policy')
      end
    end
  end
end
