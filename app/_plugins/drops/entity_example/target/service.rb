# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Target
        class Service < Base
          def to_option
            'Service'
          end
        end
      end
    end
  end
end
