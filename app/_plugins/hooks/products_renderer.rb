# frozen_string_literal: true

require_relative '../lib/build_filter'

class ProductsRenderer
  def initialize(build_filter: Jekyll::BuildFilter.current)
    @build_filter = build_filter
  end

  def read?(page)
    return false if page.relative_path.start_with?('assets')
    return true if @build_filter.content_type.include?(page.data['content_type'])
    return @build_filter.path_included?(page.url) if @build_filter.page_paths.any?

    matches_product?(page)
  end

  def render?(page)
    return false if page.relative_path.start_with?('assets')
    return true if @build_filter.content_type.include?(page.data['content_type'])
    return @build_filter.path_included?(page.url) if @build_filter.page_paths.any?

    matches_product?(page)
  end

  private

  def matches_product?(page)
    @build_filter.products.any? do |product|
      return true if page.respond_to?(:dir) && page.dir == '/'
      return true if page.url == '/how-to/'
      return true if page.url == '/plugins/'

      case product
      when '*'
        true
      else
        page.data['products']&.include?(product)
      end
    end
  end
end

build_filter = Jekyll::BuildFilter.current
renderer = ProductsRenderer.new(build_filter: build_filter)

Jekyll::Hooks.register :site, :post_read do |site|
  if build_filter.filtered?
    if build_filter.products.any?
      Jekyll.logger.info "Rendering the following products: #{build_filter.products.join(', ')}, skipping everything else..."
    else
      Jekyll.logger.info "Rendering the following urls: #{build_filter.page_paths.join(', ')}, skipping everything else..."
    end

    # Filter pages
    site.pages.delete_if do |page|
      !renderer.read?(page)
    end

    # Filter custom collections
    site.collections.each do |name, collection|
      collection.docs.delete_if do |doc|
        !renderer.read?(doc)
      end
    end
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  if build_filter.filtered?
    site.pages = site.pages.select do |page|
      renderer.render?(page)
    end
    site.documents.select do |page|
      page.data['published'] = false unless renderer.render?(page)
      page.output = false
    end
  end
end
