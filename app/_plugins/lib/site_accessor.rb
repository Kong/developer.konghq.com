# frozen_string_literal: true

module Jekyll
  module SiteAccessor
    def site
      @site ||= Jekyll.sites.first
    end

    def site_redirects
      @site_redirects ||= if Jekyll.env == 'development' && ENV['PAGE_PATHS']
                            {}
                          else
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

    def redirect_exists?(path)
      site_redirects.keys.any? { |pattern| redirect_pattern_match?(pattern, path) }
    end

    private

    def redirect_pattern_match?(pattern, path)
      regex_str = Regexp.escape(pattern)
                        .gsub('\*', '.*')
                        .gsub(/:\w+/, '[^/]+')
      Regexp.new("\\A#{regex_str}\\z").match?(path)
    end
  end
end
