# frozen_string_literal: true

module Jekyll
  module AIGatewayPluginPages
    module Pages
      class Overview < Base
        def self.url(plugin)
          "/ai-gateway/on-prem/plugins/#{plugin.slug}/"
        end

        def content
          @content ||= Jekyll::Utils::MarkdownParser.new(File.read(file)).content
        end

        def layout
          'policies/with_aside'
        end

        def data
          super.merge('overview?' => true)
        end
      end
    end
  end
end
