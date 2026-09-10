# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module CanonicalPolicy
      class BelowMinRelease
        def initialize(context)
          @context = context
        end

        def applies?
          !@context.versioned? && @context.below_min? && unpublish?
        end

        def to_h
          # Setting published: false prevents Jekyll from rendering the page.
          { 'published' => false }
        end

        private

        def unpublish?
          !data.key?('published') && !(data['plugin?'] && data['changelog?'])
        end

        def data
          @data ||= @context.page.data
        end
      end
    end
  end
end
