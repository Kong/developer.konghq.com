# frozen_string_literal: true

module Jekyll
  module ReferencePages
    module CanonicalPolicy
      Context = Struct.new(:page, :release_info, keyword_init: true) do
        def versioned?      = page.data['versioned']
        def previous_major? = MajorReleaseCalculator.new(page.data).previous_major?
        def below_min?      = min && min > release_info.latest_available_release
        def above_max?      = max && max < release_info.latest_available_release
        def url             = page.url
        def min             = release_info.min_release
        def max             = release_info.max_release
      end

      def self.for(page:, release_info:)
        context = Context.new(page:, release_info:)
        policies.lazy.map { |klass| klass.new(context) }.find(&:applies?)
      end

      def self.policies
        [BelowMinRelease, AboveMaxRelease, PreviousMajor, Default]
      end
    end
  end
end
