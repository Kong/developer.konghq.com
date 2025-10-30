# frozen_string_literal: true

require_relative '../../policies/pages/example'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Example < Base
        include Policies::Pages::Example

        def content
          @content ||= File.read('app/_includes/mesh_policies/example.md')
        end
      end
    end
  end
end
