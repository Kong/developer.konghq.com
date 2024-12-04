# frozen_string_literal: true

module Jekyll
  class PluginsGenerator < Jekyll::Generator
    priority :high

    def generate(site)
      site.data['kong_plugins'] ||= {}
      Jekyll::PluginPages::Generator.run(site)
    end
  end
end
