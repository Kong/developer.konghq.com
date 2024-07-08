# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Target
        class Consumer < Base
          def to_option
            'Consumer'
          end
        end
      end
    end
  end
end
