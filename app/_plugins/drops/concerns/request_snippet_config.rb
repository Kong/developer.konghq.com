# frozen_string_literal: true

module Jekyll
  module Drops
    module Concerns
      module RequestSnippetConfig # rubocop:disable Style/Documentation
        SNIPPET_KEYS = %w[
          url
          method
          headers
          body
          body_file
          body_cmd
          form_data
          form_url_encoded_data
          user
          sleep
          inline_sleep
          display_headers
          cookie_jar
          cookie
          message
          mtls
          count
          insecure
          expected_headers
          output
          capture
        ].freeze

        def snippet_config_for(url)
          SNIPPET_KEYS
            .to_h { |key| [key, self[key]] }
            .merge('url' => url)
            .merge(snippet_config_overrides)
        end

        def snippet_config_overrides
          {}
        end
      end
    end
  end
end
