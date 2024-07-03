# frozen_string_literal: true

module Jekyll
  class PluginGenerator < Jekyll::Generator
    priority :low

    def generate(site)
      Jekyll::KongPlugin::Generator.run(site)
    end
  end
end
