# frozen_string_literal: true

module Jekyll
  module Drops
    module Concerns
      module TestSection # rubocop:disable Style/Documentation
        VALID_SECTIONS = %w[step prereqs cleanup].freeze

        TEST_ATTRIBUTES = {
          'step' => 'data-test-step',
          'prereqs' => 'data-test-prereq',
          'cleanup' => 'data-test-cleanup'
        }.freeze

        def section
          @section ||= @yaml['section'] || 'step'
        end

        def test_attribute
          TEST_ATTRIBUTES.fetch(section)
        end

        def validate_section!
          return if VALID_SECTIONS.include?(section)

          raise ArgumentError, "#{self.class.name} sets an unrecognized section: #{section.inspect}"
        end
      end
    end
  end
end
