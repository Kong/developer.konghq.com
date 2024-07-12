# frozen_string_literal: true

require_relative './base'

module Jekyll
  module Drops
    module EntityExample
      module Target
        class Global < Base
          def to_option
            'Global'
          end
        end
      end
    end
  end
end
