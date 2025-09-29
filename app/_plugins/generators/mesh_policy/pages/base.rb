# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module MeshPolicyPages
    module Pages
      class Base # rubocop:disable Style/Documentation
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
              'breadcrumbs' => ['/mesh/', '/mesh/policies/'],
              'overview_url' => Overview.url(@policy),
              'get_started_url' => @policy.examples.first.url,
              'reference_url' => Reference.url(@policy),
              'plugin' => @policy,
              'plugin?' => true,
              'release' => @policy.latest_release_in_range,
              'icon' => icon,
              'sidebar' => false
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

        def icon
          @policy.icon
          return unless @policy.icon

          "/assets/icons/mesh_policies/#{@policy.icon}"
        end
      end
    end
  end
end
