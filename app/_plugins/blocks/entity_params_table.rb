# frozen_string_literal: true

require 'yaml'
require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class EntityParamsTable < Liquid::Block # rubocop:disable Style/Documentation
    def initialize(tag_name, markup, tokens)
      super
      @name = markup.strip
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      contents = super
      config = YAML.load(contents)
      drop = Drops::EntityParamsTable.new(config, release(@site, @page))

      context.stack do
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        context['config'] = drop
        ComponentTemplates.fetch('entity_params_table', @page['output_format']).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% entity_params_table %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end

    def release(site, page)
      return latest_release(site) unless page['release']

      release = releases(site).detect { |r| r['release'] == page['release'].number }

      if release.key?('label')
        latest_release(site)
      else
        release['release']
      end
    end

    def latest_release(site)
      @latest_release ||= releases(site).detect { |r| r['latest'] }['release']
    end

    def releases(site)
      @releases ||= site.data.dig('products', 'gateway', 'releases')
    end
  end
end

Liquid::Template.register_tag('entity_params_table', Jekyll::EntityParamsTable)
