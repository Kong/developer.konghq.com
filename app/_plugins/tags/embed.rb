# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class RenderEmbed < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      params = {}

      super

      @file, *params_list = @markup.split(' ')

      params_list.each do |item|
        sp = item.split('=')
        params[sp[0]] = sp[1]
      end

      @versioned = params.key?('versioned')
    end

    def render(context) # rubocop:disable Metrics/MethodLength
      site = context.registers[:site]
      @page = context.environments.first['page']
      embedded_file_path = file_path(@page['release'])

      begin
        content = File.read(embedded_file_path).gsub('# Changelog', '')

        ignored_links(site).reduce(content) do |result, pattern|
          result.gsub(Regexp.new(pattern), '')
        end
      rescue StandardError
        raise ArgumentError, "Failed to read the raw file `#{embedded_file_path}` in {% embed %} on #{@page['path']}."
      end
    end

    def file_path(release)
      if @versioned
        [
          File.join('app/assets/mesh/', release, 'raw', @file),
          File.join('app/assets/mesh/', "#{release}.x", 'raw', @file)
        ].find { |full_path| File.exist?(full_path) }
      else
        File.join('app/assets/mesh/raw/', @file)
      end
    end

    def ignored_links(site)
      @ignored_links ||= site.config.dig('mesh', 'ignored_links_regex') || []
    end
  end
end

Liquid::Template.register_tag('embed', Jekyll::RenderEmbed)
