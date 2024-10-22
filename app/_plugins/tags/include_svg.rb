# frozen_string_literal: true

module Jekyll
  class IncludeSVGTag < Liquid::Tag

    def initialize(tag_name, file_path, tokens)
      super
      @file_path = file_path.strip
    end

    def render(context)
      # Construct the full path to the SVG file in assets
      site_source = context.registers[:site].source
      file_path = context[@file_path]
      full_path = File.join(site_source, file_path)

      # Read and return the SVG content if the file exists
      if File.exist?(full_path)
        File.read(full_path)
      else
        raise ArgumentError.new("SVG file not found: #{full_path}")
      end
    end
  end
end

Liquid::Template.register_tag('include_svg', Jekyll::IncludeSVGTag)
