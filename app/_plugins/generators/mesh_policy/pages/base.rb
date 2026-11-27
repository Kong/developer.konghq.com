# frozen_string_literal: true

require_relative '../../policies/pages/base'
require_relative '../../../lib/major_version_resolver'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Base # rubocop:disable Style/Documentation
        include Policies::Pages::Base

        def self.base_url(policy)
          return '/mesh/policies/' unless policy.explicit_major

          "/mesh/#{version_segment(policy)}/policies/"
        end

        def self.version_segment(policy)
          product_data = policy.site.data.dig('products', policy.product)
          MajorVersionResolver.process(product_data:, major: policy.policy_major)
        end

        def breadcrumbs
          @breadcrumbs ||= if @policy.explicit_major
                             segment = self.class.version_segment(@policy)
                             ["/mesh/#{segment}/", "/mesh/#{segment}/policies/"]
                           else
                             ['/mesh/', '/mesh/policies/']
                           end
        end

        def icon
          return unless @policy.icon

          "/assets/icons/mesh_policies/#{@policy.icon}"
        end
      end
    end
  end
end
