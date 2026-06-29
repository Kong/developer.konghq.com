# frozen_string_literal: true

module Jekyll
  module ReleaseInfo
    class MajorResolver # rubocop:disable Style/Documentation
      class InvalidMajorVersion < StandardError; end

      def initialize(site:, product:, page_major_version:, min_version:, max_version:)
        @site = site
        @product = product
        @page_major_version = page_major_version
        @min_version = min_version
        @max_version = max_version
      end

      def resolve
        return if releases.empty?

        validate_major_exists!
        validate_min!
        validate_max!
        major
      end

      private

      def major
        @major ||= requested_major || current_major
      end

      def requested_major
        @page_major_version&.fetch(@product, nil)
      end

      def current_major
        latest = releases.detect { |r| r['latest'] }
        raise InvalidMajorVersion, "No release flagged `latest: true` for product `#{@product}`" if latest.nil?

        major_of(latest['release'])
      end

      def validate_major_exists!
        return if available_majors.include?(major)

        raise InvalidMajorVersion,
              "Page declares `major_version.#{@product}=#{major}` " \
              "but only majors #{available_majors} exist in `app/_data/products/#{@product}.yml`"
      end

      def validate_min!
        return if @min_version.nil?
        return if @page_major_version.nil?
        return if major_of(@min_version) <= major

        raise InvalidMajorVersion,
              "Page declares `min_version.#{@product}=#{@min_version}` (major #{major_of(@min_version)}) " \
              "but resolved major is #{major}"
      end

      def validate_max!
        return if @max_version.nil?
        return if major_of(@max_version) == major

        raise InvalidMajorVersion,
              "Page declares `max_version.#{@product}=#{@max_version}` (major #{major_of(@max_version)}) " \
              "but resolved major is #{major}"
      end

      def releases
        @releases ||= @site.data.dig('products', @product, 'releases') || []
      end

      def available_majors
        @available_majors ||= releases.map { |r| major_of(r['release']) }.uniq
      end

      def major_of(version_string)
        version_string.to_s.split('.').first.to_i
      end
    end
  end
end
