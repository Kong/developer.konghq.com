# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module CanonicalPolicy
      class Default
        def initialize(context)
          @context = context
        end

        def applies?
          true
        end

        def to_h
          { 'canonical_url' => @context.url, 'canonical?' => true }
        end
      end
    end
  end
end
