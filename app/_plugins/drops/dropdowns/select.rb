# frozen_string_literal: true

require_relative './option'

module Jekyll
  module Drops
    module Dropdowns
      class Select < Liquid::Drop
        def initialize(options)
          @options = options
        end

        def options
          @options
        end

        def any?
          options.any?
        end
      end
    end
  end
end
