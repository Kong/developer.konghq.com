# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class Konnect < Base
          def template_file(_type)
            @template_file ||= '/components/entity_example/format/konnect.html'
          end

          def to_option
            'Konnect'
          end
        end
      end
    end
  end
end
