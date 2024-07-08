# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Target
        class Route < Base
          def to_option
            'Route'
          end
        end
      end
    end
  end
end
