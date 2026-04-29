# frozen_string_literal: true

module Jekyll
  module SiteAccessor
    def site
      @site ||= Jekyll.sites.first
    end

    def site_redirects
      @site_redirects ||= begin
        return {} if Jekyll.env == 'development' && ENV['PAGE_PATHS']

        site.pages.detect do |p|
          p.url == '/_redirects'
        end.content.lines.each_with_object({}) do |line, hash|
          line = line.strip

          # Skip blank lines and comments
          next if line.empty? || line.start_with?('#')

          parts = line.split(/\s+/)

          # Only proceed if we have at least a source and destination
          next unless parts.size >= 2

          source = parts[0]
          destination = parts[1]
          hash[source] = destination
        end
      end
    end
  end
end
