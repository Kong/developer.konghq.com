# frozen_string_literal: true

require 'nokogiri'
require_relative '../monkey_patch'

module Jekyll
  class IncludeSVGTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @params = parse_markup(markup)
    end

    def render(context)
      file_path = @params['file_path']

      site_source = context.registers[:site].source
      file_path = context[file_path]
      full_path = File.join(site_source, file_path)

      raise ArgumentError, "SVG file not found: #{full_path}" unless File.exist?(full_path)

      svg_content = File.read(full_path)
      doc = Nokogiri::XML(svg_content)
      svg = doc.at_css('svg')

      svg['width'] = @params['width'] if @params['width']
      svg['height'] = @params['height'] if @params['height']

      doc.to_s
    end

    def parse_markup(markup)
      params = {}

      # Split markup into key=value pairs or the first path segment
      parts = markup.split(/\s+/)
      params['file_path'] = parts.shift

      parts.each do |part|
        if part =~ /(\w+)=(.+)/
          key = Regexp.last_match(1)
          value = Regexp.last_match(2).gsub(/^["']|["']$/, '') # strip surrounding quotes
          params[key] = value
        end
      end

      params
    end
  end
end

Liquid::Template.register_tag('include_svg', Jekyll::IncludeSVGTag)

