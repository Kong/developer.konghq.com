# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class KonnectAPI < Base
          def template_file(_type)
            @template_file ||= '/components/entity_example/format/konnect.md'
          end

          def to_option
            'Konnect API'
          end
        end
      end
    end
  end
end
