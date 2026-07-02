# frozen_string_literal: true

module Jekyll
  class AIGatewayPluginsGenerator < Jekyll::Generator
    priority :normal

    def generate(site)
      site.data['ai_gateway_plugins'] ||= {}
      Jekyll::AIGatewayPluginPages::Generator.run(site)
    end
  end
end
