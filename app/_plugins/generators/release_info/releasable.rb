# frozen_string_literal: true

module Jekyll
  module ReleaseInfo
    module Releasable
      def releases
        @releases ||= available_releases.select do |r|
          Utils::Version.in_range?(r['release'], min: min_release, max: max_release)
        end
      end

      def latest_available_release
        @latest_available_release ||= available_releases.detect(&:latest?)
      end

      def min_release
        @min_release ||= min_version && available_releases.detect { |r| r['release'] == min_version.to_s }
      end

      def max_release
        @max_release ||= max_version && available_releases.detect { |r| r['release'] == max_version.to_s }
      end

      def latest_release_in_range
        @latest_release_in_range ||= begin
          return min_release if min_release && min_release > latest_available_release
          return max_release if max_release && max_release < latest_available_release

          latest_available_release
        end
      end

      def unreleased?
        latest_release_in_range != latest_available_release
      end

      private

      def min_version
        @min_version[key]
      end

      def max_version
        @max_version[key]
      end
    end
  end
end
