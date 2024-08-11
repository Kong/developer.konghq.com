# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class Deck < Base
          def template_file(_type)
            @template_file ||= '/components/entity_example/format/deck.md'
          end

          def to_option
            'decK'
          end
        end
      end
    end
  end
end
