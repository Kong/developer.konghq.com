# frozen_string_literal: true

module Jekyll
  class BuildFilter
    def self.current
      @current ||= new
    end

    def initialize(env: ENV)
      @env = env
      @jekyll_env = Jekyll.env
    end

    def development?
      @jekyll_env == 'development'
    end

    def content_type
      @content_type ||= (@env['CONTENT_TYPE'] || '').split(',').map(&:strip).reject(&:empty?)
    end

    def products
      @products ||= @env.fetch('KONG_PRODUCTS', '').split(',')
    end

    def page_paths
      @page_paths ||= (@env['PAGE_PATHS'] || '').split(',').map(&:strip).reject(&:empty?)
    end

    def filtered?
      development? &&
        (!@env['KONG_PRODUCTS'].nil? || !@env['PAGE_PATHS'].nil? || !@env['CONTENT_TYPE'].nil?)
    end

    def path_included?(url)
      page_paths.any? { |path| url.start_with?(path) }
    end

    def excludes_prefix?(prefix)
      development? && page_paths.any? && page_paths.none? { |path| path.start_with?(prefix) }
    end
  end
end
