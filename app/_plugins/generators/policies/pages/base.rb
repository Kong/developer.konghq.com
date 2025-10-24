# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module Policies
    module Pages
      module Base # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        attr_reader :file

        def initialize(policy:, file:)
          @policy = policy
          @file   = file
        end

        def to_jekyll_page
          CustomJekyllPage.new(site:, page: self)
        end

        def dir
          url
        end

        def data # rubocop:disable Metrics/MethodLength
          @policy
            .metadata
            .merge(
              'slug' => @policy.slug,
              'layout' => layout,
              'breadcrumbs' => breadcrumbs,
              'overview_url' => @policy.overview_page_class.url(@policy),
              'get_started_url' => @policy.examples.first&.url,
              'reference_url' => @policy.reference_page_class.url(@policy),
              'plugin' => @policy,
              'plugin?' => true,
              'release' => @policy.latest_release_in_range,
              'icon' => icon
            ).merge(publication_info)
        end

        def relative_path
          @relative_path = file.gsub("#{site.source}/", '')
        end

        def url
          @url ||= self.class.url(@policy)
        end

        def publication_info
          return {} if @policy.publish?

          { 'published' => false }
        end
      end
    end
  end
end
