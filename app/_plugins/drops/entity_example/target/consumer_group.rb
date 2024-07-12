# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Target
        class ConsumerGroup < Base
          def to_option
            'Consumer Group'
          end
        end
      end
    end
  end
end
