# frozen_string_literal: true

module Jekyll
  module MeshPolicyPages
    module Pages
      class Reference < Base # rubocop:disable Style/Documentation
        def self.url(policy)
          if policy.unreleased?
            "/mesh/policies/#{policy.slug}/reference/#{policy.min_release}/"
          else
            "/mesh/policies/#{policy.slug}/reference/"
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

        def layout
          'policies/reference'
        end
      end
    end
  end
end
