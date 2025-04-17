# frozen_string_literal: true

module Jekyll
  class MeshPoliciesGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      site.data['mesh_policies'] ||= {}
      Jekyll::MeshPolicyPages::Generator.run(site)
    end
  end
end
