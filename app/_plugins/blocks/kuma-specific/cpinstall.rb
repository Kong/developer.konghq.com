# frozen_string_literal: true

# Extracted from: https://github.com/kumahq/kuma-website/blob/master/jekyll-kuma-plugins/lib/jekyll/kuma-plugins/liquid/tags/cpinstall.rb
require_relative '../../component_templates'

module Jekyll
  module KumaSpecific
    class CpInstall < Liquid::Block # rubocop:disable Style/Documentation
      def initialize(tag_name, markup, options)
        super
        _, *params_list = markup.split
        params = { 'prefixed' => 'true' }
        params_list.each do |item|
          sp = item.split('=')
          params[sp[0]] = sp[1] unless sp[1] == ''
        end
        @prefixed = params['prefixed'].downcase == 'true'
      end

      def render(context)
        content = super
        return '' if content.empty?

        site = context.registers[:site]
        page = context.environments.first['page']
        drop = Drops::KumaSpecific::CpInstall.new(content, site.config, page, @prefixed)

        context.stack do
          context['config'] = drop
          ComponentTemplates.fetch('kuma_specific/cpinstall', 'markdown').render(context)
        end
      end
    end
  end
end

Liquid::Template.register_tag('cpinstall', Jekyll::KumaSpecific::CpInstall)
