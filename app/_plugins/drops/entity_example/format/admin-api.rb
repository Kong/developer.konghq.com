# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class AdminAPI < Base
          def template_file(_type)
            @template_file ||= '/components/entity_example/format/admin-api.html'
          end

          def to_option
            'Admin API'
          end
        end
      end
    end
  end
end
