# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class Deck < Base
          def template_file(type)
            @template_file ||= "/components/entity_example/#{type}/deck.md"
          end

          def to_option
            'decK'
          end
        end
      end
    end
  end
end
