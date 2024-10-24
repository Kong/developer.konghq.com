# frozen_string_literal: true

module Jekyll
  module Drops
    class ReleasesDropdown < Liquid::Drop
      class Option < Liquid::Drop
        attr_reader :release

        def initialize(base_url:, release:)
          @base_url = base_url
          @release  = release
        end

        def value
          @value ||= @release['label'] || @release['release']
        end

        def url
          @url ||= if latest?
                     @base_url
                   else
                     "#{@base_url}#{value}/"
                   end
        end

        def lts?
          !!@release['lts']
        end

        def latest?
          !!@release['latest']
        end
      end

      attr_reader :base_url

      def initialize(base_url:, releases:)
        @base_url = base_url
        @releases = releases
      end

      def options
        @options ||= @releases.sort.reverse.map do |release|
          Option.new(base_url:, release:)
        end
      end

      def hash
        @hash ||= base_url.hash
      end
    end
  end
end
