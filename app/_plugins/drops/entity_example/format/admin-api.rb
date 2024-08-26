# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class AdminAPI < Base
          def template_file
            @template_file ||= "/components/entity_example/format/admin-api.md"
          end

          def to_option
            'Admin API'
          end
        end
      end
    end
  end
end
