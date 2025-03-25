# frozen_string_literal: true

module Jekyll
  module Drops
    class Release < Liquid::Drop # rubocop:disable Style/Documentation
      include Comparable
      include Jekyll::SiteAccessor

      attr_reader :release_hash

      def initialize(release_hash) # rubocop:disable Lint/MissingSuper
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

      def number
        @number ||= @release_hash['release']
      end

      def ee_version
        @ee_version ||= @release_hash['ee-version']
      end

      def major_minor_version
        @major_minor_version ||= number.gsub('.', '')
      end

      def distros_by_os # rubocop:disable Metrics/AbcSize
        @distros_by_os ||= @release_hash
                           .fetch('distributions', [])
                           .each_with_object(Hash.new { |h, k| h[k] = [] }) do |distro, h|
          key = distro.keys.first
          os = key[/^\D+/]

          h[os] << {
            'codename' => site.data.dig('support', 'packages', key, 'codename'),
            'version_number' => site.data.dig('support', 'packages', key, 'version').to_s[/\d+(\.\d+)?/]
          }.merge(distro.values.first)
        end
      end

      def lts
        @release_hash['lts']
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
        Gem::Version.new(@release_hash['release']) <=> Gem::Version.new(other['release'])
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
