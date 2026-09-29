# frozen_string_literal: true

require_relative '../../policies/pages/reference'
require_relative '../../../file_cache'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Reference < Base
        include Policies::Pages::Reference

        def layout
          'mesh_policies/reference'
        end

        def markdown_content
          @markdown_content ||= FileCache.read('app/_includes/mesh_policies/reference.md')
        end

      end
    end
  end
end
