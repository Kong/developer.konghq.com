# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class KonnectAPI < Base
          def template_file(type)
            @template_file ||= "/components/entity_example/#{type}/konnect-api.md"
          end

          def to_option
            'Konnect API'
          end
        end
      end
    end
  end
end
