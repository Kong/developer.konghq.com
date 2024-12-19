# frozen_string_literal: true

module Jekyll
  module SiteAccessor
    def site
      @site ||= Jekyll.sites.first
    end
  end
end
