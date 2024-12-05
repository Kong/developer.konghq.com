# frozen_string_literal: true

module Jekyll
  module Drops
    class Release < Liquid::Drop
      include Comparable

      attr_reader :release_hash

      def initialize(release_hash)
        @release_hash = release_hash
      end

      def latest?
        @release_hash['latest']
      end

      def label?
        @release_hash['label']
      end

      def to_konnect_version
        @release_hash['ee-version'].sub(/^(\d+\.\d+)\.\d+.*$/, '\1.0.0')
      end

      def to_str
        if @release_hash.key?('label')
          @release_hash['label']
        else
          @release_hash['release']
        end
      end
      alias to_s to_str

      def hash
        @hash ||= @release_hash['release'].hash
      end

      def <=>(other)
        @release_hash['release'] <=> other['release']
      end

      def [](key)
        key = key.to_s
        if respond_to?(key)
          public_send(key)
        else
          @release_hash[key]
        end
      end
    end
  end
end
