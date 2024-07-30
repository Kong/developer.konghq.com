# frozen_string_literal: true

module Jekyll
  class PluginPagesGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      collection = site.collections['kong_plugins']
      collection.docs.map do |doc|
        slug = doc.relative_path
          .gsub("#{collection.relative_directory}/", '')
          .gsub("/#{doc.basename}", '')

        doc.data['slug'] = slug
        doc.data['permalink'] = "/plugins/#{slug}/"
      end
    end
  end
end
