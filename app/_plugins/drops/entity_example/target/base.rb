# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Target
        class Base < Liquid::Drop
          def initialize(target:)
            @target = target
          end

          def value
            @value ||= @target.value
          end

          def to_option
            raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
          end
        end
      end
    end
  end
end
