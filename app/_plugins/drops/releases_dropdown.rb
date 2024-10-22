# frozen_string_literal: true

module Jekyll
  module Drops
    class ReleasesDropdown < Liquid::Drop
      class Option < Liquid::Drop
        def initialize(page:, release:)
          @page    = page
          @release = release
        end

        def value
          @value ||= @release['label'] || @release['release']
        end

        def url
          @url ||= if @release == @page.data['canonical_release']
            @page.data['canonical_url']
          else
            "#{@page.data['canonical_url']}#{value}/"
          end
        end

        def lts?
          !!@release['lts']
        end

        def latest?
          !!@release['latest']
        end

        def selected?
          @page.data['release'] == @release
        end
      end

      attr_reader :page

      def initialize(page:, releases:)
        @page     = page
        @releases = releases
      end

      def options
        @options ||= @releases.map do |release|
          Option.new(page:, release:)
        end
      end

      def hash
        @hash ||= "#{@page.data['products']}-#{@page.data['release']}-#{@page.dir}".hash
      end
    end
  end
end