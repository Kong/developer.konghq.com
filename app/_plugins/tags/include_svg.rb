# frozen_string_literal: true

require 'nokogiri'
require_relative '../monkey_patch'

module Jekyll
  class IncludeSVGTag < Liquid::Tag
    ALLOWED_ATTRS = %w[role class focusable id].freeze
    RESERVED = %w[file_path width height].freeze
    TOKEN_RE = /[\w-]+=(?:"[^"]*"|'[^']*'|\S+)|\S+/.freeze

    def initialize(tag_name, markup, tokens)
      super
      @params = parse_markup(markup)
    end

    def render(context)
      file_path = context[@params['file_path']]
      full_path = File.join(context.registers[:site].source, file_path)

      raise ArgumentError, "SVG file not found: #{full_path}" unless File.exist?(full_path)

      build_svg(File.read(full_path), context).to_s
    end

    private

    def build_svg(svg_content, context)
      doc = Nokogiri::XML(svg_content)
      svg = doc.at_css('svg')
      svg['width']  = context[@params['width']]  if @params['width']
      svg['height'] = context[@params['height']] if @params['height']
      apply_attrs(svg, context)
      doc
    end

    def apply_attrs(svg, context)
      @params.each do |key, value|
        next if RESERVED.include?(key)
        next unless allowed_attr?(key)

        svg[key] = context[value]
      end
    end

    def allowed_attr?(key)
      key.match?(/\Aaria-[\w-]+\z/) || ALLOWED_ATTRS.include?(key)
    end

    def parse_markup(markup)
      parts = markup.scan(TOKEN_RE)
      params = { 'file_path' => parts.shift }
      parts.each do |part|
        next unless part =~ /\A([\w-]+)=(.+)\z/

        params[Regexp.last_match(1)] = Regexp.last_match(2)
      end
      params
    end
  end
end

Liquid::Template.register_tag('include_svg', Jekyll::IncludeSVGTag)
