# frozen_string_literal: true

module Jekyll
  module MeshPolicyPages
    module Pages
      class Overview < Base # rubocop:disable Style/Documentation
        def self.url(policy)
          if policy.unreleased?
            "/mesh/policies/#{policy.slug}/#{policy.min_release}/"
          else
            "/mesh/policies/#{policy.slug}/"
          end
        end

        def content
          @content ||= parser.content
        end

        def layout
          'policies/with_aside'
        end

        def data
          super.merge('overview?' => true)
        end

        private

        def parser
          @parser ||= Jekyll::Utils::MarkdownParser.new(File.read(file))
        end
      end
    end
  end
end
