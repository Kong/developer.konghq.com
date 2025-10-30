# frozen_string_literal: true

module Jekyll
  class RefirectsGenerator < Jekyll::Generator
    priority :lowest

    def generate(site)
      redirects = api_specs_redirects(site)
      redirects << plugin_examples_redirects(site)
      redirects << mesh_examples_redirects(site)
      redirects << event_gateway_examples_redirects(site)
      redirects << existing_redirects(site)

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

    def mesh_examples_redirects(site)
      site.data.fetch('mesh_policies', {}).map do |_slug, policy|
        ["#{policy.url}examples/", policy.data.fetch('get_started_url')].join("\t")
      end
    end

    def event_gateway_examples_redirects(site)
      site.data.fetch('event_gateway_policies', {}).map do |_slug, policy|
        if policy.data.fetch('get_started_url')
          ["#{policy.url}examples/",
           policy.data.fetch('get_started_url')].join("\t")
        end
      end
    end

    def existing_redirects(site)
      @existing_redirects ||= File.readlines(
        File.join(site.source, '_redirects'),
        chomp: true
      )
    end
  end
end
