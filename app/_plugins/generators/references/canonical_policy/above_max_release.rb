# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module CanonicalPolicy
      class AboveMaxRelease
        def initialize(context)
          @context = context
        end

        def applies?
          !@context.versioned? && @context.above_max?
        end

        def to_h
          {
            'published' => false,
            'canonical_url' => "#{@context.url}#{@context.max}/"
          }
        end
      end
    end
  end
end
