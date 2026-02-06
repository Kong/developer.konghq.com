# frozen_string_literal: true

require_relative '../../policies/pages/reference'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Reference < Base
        include Policies::Pages::Reference

        def layout
          'mesh_policies/reference'
        end

        def markdown_content
          @markdown_content ||= File.read('app/_includes/mesh_policies/reference.md')
        end

      end
    end
  end
end
