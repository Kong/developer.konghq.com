# frozen_string_literal: true

require_relative '../../policies/pages/example'
require_relative '../../../file_cache'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Example < Base
        include Policies::Pages::Example

        def content
          @content ||= FileCache.read('app/_includes/mesh_policies/example.md')
        end
      end
    end
  end
end
