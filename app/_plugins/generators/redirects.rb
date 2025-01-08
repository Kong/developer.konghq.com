# frozen_string_literal: true

module Jekyll
  class RefirectsGenerator < Jekyll::Generator
    priority :lowest

    def generate(site)
      redirects = api_specs_redirects(site)
      redirects << plugin_examples_redirects(site)

      site.pages << build_page(redirects, site)
    end

    def build_page(redirects, site)
      page = PageWithoutAFile.new(site, __dir__, '', '_redirects')
      page.data['layout'] = nil
      page.content = redirects.join("\n")
      page
    end

    def api_specs_redirects(site)
      site.data.fetch('ssg_api_pages', []).map do |page|
        [page.data['base_url'], page.url].join("\t")
      end
    end

    def plugin_examples_redirects(site)
      site.data.fetch('kong_plugins', {}).map do |_slug, plugin|
        ["#{plugin.url}examples/", plugin.data.fetch('get_started_url')].join("\t")
      end
    end
  end
end
