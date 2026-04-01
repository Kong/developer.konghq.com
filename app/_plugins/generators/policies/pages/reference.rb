# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module Policies
    module Pages
      module Reference # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods # rubocop:disable Style/Documentation
          def url(policy)
            if policy.unreleased?
              "#{base_url}#{policy.slug}/reference/#{policy.min_release}/"
            else
              "#{base_url}#{policy.slug}/reference/"
            end
          end
        end

        def content
          ''
        end

        def data
          super
            .except('faqs')
            .merge(
              'content_type' => 'reference',
              'reference?' => true,
              'toc' => false,
              'versioned' => true,
              'schema' => @policy.schema
            )
        end
      end
    end
  end
end
