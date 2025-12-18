# frozen_string_literal: true

class ProductsRenderer
  def products
    @products ||= ENV.fetch('KONG_PRODUCTS', '')
                     .split(',')
  end

  def read?(page)
    return false if page.relative_path.start_with?('assets')

    products.any? do |product|
      return true if page.respond_to?(:dir) && page.dir == '/'
      return true if page.url == '/how-to/'

      case product
      when '*'
        true
      else
        page.data['products']&.include?(product)
      end
    end
  end

  def render?(page)
    return false if page.relative_path.start_with?('assets')

    products.any? do |product|
      return true if page.respond_to?(:dir) && page.dir == '/'
      return true if page.url == '/how-to/'

      case product
      when '*'
        true
      else
        page.data['products']&.include?(product)
      end
    end
  end
end

renderer = ProductsRenderer.new

Jekyll::Hooks.register :site, :post_read do |site|
  if ENV['KONG_PRODUCTS']
    Jekyll.logger.info "Rendering the following products: #{ENV['KONG_PRODUCTS']}, skipping everything else..."

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
  if ENV['KONG_PRODUCTS']
    site.pages = site.pages.select do |page|
      renderer.render?(page)
    end
    site.documents.select do |page|
      page.data['published'] = false unless renderer.render?(page)
      page.output = false
    end
  end
end
