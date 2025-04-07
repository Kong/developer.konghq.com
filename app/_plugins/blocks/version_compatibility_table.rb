# frozen_string_literal: true

require 'yaml'

module Jekyll
  class VersionCompatibilityTable < Liquid::Block
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super

      config = YAML.load(contents)

      config = convert_version_compat_to_feature_table(config)

      context.stack do
        context['include'] =
          { 'columns' => config['columns'], 'rows' => config['features'], 'item_title' => config['item_title'] }
        Liquid::Template.parse(template).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% version_compatibility_table %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    private

    def convert_version_compat_to_feature_table(config)
      {
        'item_title' => config['product'],
        'columns' => config['versions'].map do |version|
          { 'title' => "#{version}.x", 'key' => version.to_s }
        end,
        'features' => config['compatible_versions'].map do |compatible_version, supported_versions|
          feature = { 'title' => "#{config['compatible_product']} #{compatible_version}" }
          config['versions'].each do |version|
            feature[version.to_s] = supported_versions.include?(version)
          end
          feature
        end
      }
    end

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/feature_table.html'))
    end
  end
end

Liquid::Template.register_tag('version_compatibility_table', Jekyll::VersionCompatibilityTable)
