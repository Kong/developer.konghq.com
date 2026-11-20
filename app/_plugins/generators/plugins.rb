# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class PluginsGenerator < OrderedGenerator
    def generate(site)
      site.data['kong_plugins'] ||= {}
      Jekyll::PluginPages::Generator.run(site)
    end
  end
end
