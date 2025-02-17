# frozen_string_literal: true

module Jekyll
  module Utils
    class Version # rubocop:disable Style/Documentation
      def self.in_range?(input, min: nil, max: nil) # rubocop:disable Metrics/MethodLength
        version = Gem::Version.new(input)

        lower_limit = nil
        if min
          min = min.is_a?(Drops::Release) ? min['release'] : min
          lower_limit = ">= #{min}"
        end

        upper_limit = nil
        if max
          max = max.is_a?(Drops::Release) ? max['release'] : max
          upper_limit = "<= #{max}"
        end

        Gem::Requirement
          .new([lower_limit, upper_limit])
          .satisfied_by?(version)
      end
    end
  end
end
