# frozen_string_literal: true

module Jekyll
  module Drops
    module Dropdowns
      class Option < Liquid::Drop
        def initialize(value:, text:)
          @value = value
          @text  = text
        end

        def value
          @value
        end

        def text
          @text
        end
      end
    end
  end
end
