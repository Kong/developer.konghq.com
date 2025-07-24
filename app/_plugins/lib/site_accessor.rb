# frozen_string_literal: true

module Jekyll
  module SiteAccessor
    def site
      @site ||= Jekyll.sites.first
    end

    def site_redirects
      @site_redirects ||= site.pages.detect { |p| p.url == '/_redirects' }.content.lines.each_with_object({}) do |line, hash|
        line = line.strip

        # Skip blank lines and comments
        next if line.empty? || line.start_with?('#')

        parts = line.split(/\s+/)

        # Only proceed if we have at least a source and destination
        if parts.size >= 2
          source = parts[0]
          destination = parts[1]
          hash[source] = destination
        end
      end
    end
  end
end
