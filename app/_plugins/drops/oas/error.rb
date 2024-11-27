# frozen_string_literal: true

module Jekyll
  module Drops
    module OAS
      class Error < Liquid::Drop
        def initialize(code:, values:)
          @code = code
          @values = values
        end

        def key
          @key ||= @code
        end

        def description
          @description ||= @values.fetch('description')
        end

        def resolution
          @resolution ||= @values.fetch('resolution')
        end
      end
    end
  end
end
