# frozen_string_literal: true

module Jekyll
  module KumatoMesh
    class Converter # rubocop:disable Style/Documentation
      include Jekyll::SiteAccessor

      attr_reader :page

      def initialize(page)
        @page = page
      end

      def process
        replace_kuma_with_kong_mesh_in_links
        replace_exact_links
        replace_kuma_base_url
        set_edit_url
      end

      private

      def replace_kuma_with_kong_mesh_in_links
        # Links can be wrapped with " (html) or ( and ) (markdown)
        page.content = page
                       .content
                       # only consider urls that start with / or #
                       .gsub(%r{([("][/#](?!assets/).*)kuma(?!(?:-cp|-dp|ctl))([^\s]*)([)"])}) do |s|
                         # replace kuma to kong-mesh as many times as it occurs but do not replace
                         # kuma.io or kumaio (These are annotations and should remain unchanged)
                         s.gsub(/kuma(?!(\.?io))/, 'kong-mesh')
                       end
      end

      def replace_exact_links
        site.data.dig('kuma_to_mesh', 'config', 'links').each do |k, v|
          page.content = page.content.gsub(/([("])#{k}([)"])/, "\\1#{v}\\2")
        end
      end

      def replace_kuma_base_url
        page.content = page
                       .content
                       .gsub(%r{/docs/{{\s*page.release\s*}}}, '/mesh')
      end

      def set_edit_url
        path = page.relative_path.gsub('app/.repos/kuma/', '')
        page.data['edit_link'] = "https://github.com/kumahq/kuma-website/edit/master/#{path}"
      end
    end
  end
end
