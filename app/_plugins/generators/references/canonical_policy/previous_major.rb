# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module CanonicalPolicy
      class PreviousMajor
        def initialize(context)
          @context = context
        end

        def applies?
          @context.previous_major?
        end

        def to_h
          { 'canonical?' => false }
        end
      end
    end
  end
end
