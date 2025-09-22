# frozen_string_literal: true

require_relative '../../../lib/site_accessor'

module Jekyll
  module Policies
    module Pages
      module Overview # rubocop:disable Style/Documentation
        include Jekyll::SiteAccessor

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods # rubocop:disable Style/Documentation
          def url(policy)
            if policy.unreleased?
              "#{base_url}#{policy.slug}/#{policy.min_release}/"
            else
              "#{base_url}#{policy.slug}/"
            end
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
