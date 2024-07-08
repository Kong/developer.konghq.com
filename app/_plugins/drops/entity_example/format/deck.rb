# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Format
        class Deck < Base
          def entity
            @entity ||= Formatters::Deck::Base
              .make_for(type: @type, target: @target, data: @data)
              .entity
          end

          def data
            @_data ||= Formatters::Deck::Base
              .make_for(type: @type, target: @target, data: @data)
              .data
          end

          def template_file(_type)
            @template_file ||= '/components/entity_example/format/deck.html'
          end

          def to_option
            'Deck'
          end
        end
      end
    end
  end
end
