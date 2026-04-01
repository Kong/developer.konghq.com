# frozen_string_literal: true

require_relative '../../policies/pages/base'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Base # rubocop:disable Style/Documentation
        include Policies::Pages::Base

        def self.base_url
          '/mesh/policies/'
        end

        def breadcrumbs
          @breadcrumbs ||= ['/mesh/', '/mesh/policies/']
        end

        def icon
          return unless @policy.icon

          "/assets/icons/mesh_policies/#{@policy.icon}"
        end
      end
    end
  end
end
