# frozen_string_literal: true

module Jekyll
  module Utils
    class Version
      def self.in_range?(input, min: nil, max: nil)
        version = Gem::Version.new(input)

        lower_limit = min ? ">= #{min['release']}" : nil
        upper_limit = max ? "<= #{max['release']}" : nil

        Gem::Requirement
          .new([lower_limit, upper_limit])
          .satisfied_by?(version)
      end
    end
  end
end