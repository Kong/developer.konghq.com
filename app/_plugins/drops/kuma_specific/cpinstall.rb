# frozen_string_literal: true

module Jekyll
  module Drops
    module KumaSpecific
      class CpInstall < Liquid::Drop # rubocop:disable Style/Documentation
        def initialize(content, site_config, page, prefixed) # rubocop:disable Lint/MissingSuper
          @content = content
          @site_config = site_config
          @page = page
          @prefixed = prefixed
        end

        def helm_flags
          @helm_flags ||= @content.strip.split("\n").map do |line|
            line = @site_config['set_flag_values_prefix'] + line if @prefixed
            "--set \"#{line}\""
          end.join(" \\\n  ")
        end

        def product_url_segment
          @page['dir'].split('/')[1]
        end

        def page_release
          @page['release']
        end

        def product_name
          @site_config['mesh_product_name']
        end

        def namespace
          @site_config['mesh_namespace']
        end

        def helm_install_name
          @site_config['mesh_helm_install_name']
        end

        def helm_repo
          @site_config['mesh_helm_repo']
        end

        def web_url
          @site_config['links']['web']
        end
      end
    end
  end
end
