# frozen_string_literal: true

module Jekyll
  module APIPages
    module URLGenerator
      class API
        def initialize(file:, version:)
          @file = file
          @version = version
        end

        def canonical_url
          @canonical_url ||= file_to_url
        end

        def versioned_url
          @versioned_url ||= "#{canonical_url}#{version_segment}/"
        end

        def file_to_url
          @file_to_url ||= @file
                           .gsub('_index.md', '')
                           .gsub('_api', '/api')
        end

        def version_segment
          @version_segment ||= @version.to_s
        end
      end
    end
  end
end
