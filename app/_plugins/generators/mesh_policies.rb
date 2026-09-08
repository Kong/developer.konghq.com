# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class MeshPoliciesGenerator < OrderedGenerator # rubocop:disable Style/Documentation
    def generate(site)
      site.data['mesh_policies'] ||= {}
      Jekyll::MeshPolicyPages::Generator.run(site)
    end
  end
end
