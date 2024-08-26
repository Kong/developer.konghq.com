# frozen_string_literal: true

module Jekyll
  module Drops
    module EntityExample
      module Format
        class Base < Liquid::Drop
          def initialize(format:)
            @format = format
          end

          def value
            @value ||= @format.value
          end

          def template_file(collection)
            raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
          end

          def to_option
            raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
          end
        end
      end
    end
  end
end
