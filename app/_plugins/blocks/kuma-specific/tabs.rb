# frozen_string_literal: true

require 'erb'
require 'securerandom'

module Jekyll
  module KumaSpecific
    class TabsBlock < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super

        @class = markup.strip.empty? ? '' : " #{markup.strip}"
      end

      def render(context)
        tabs_id = SecureRandom.uuid
        site = context.registers[:site]
        environment = context.environments.first
        environment["navtabs-#{tabs_id}"] = {}
        environment['navtabs-stack'] ||= []
        environment['navtabs-stack'].push(tabs_id)

        super

        environment['navtabs-stack'].pop
        environment['additional_classes'] = @class

        Liquid::Template
          .parse(File.read(File.join(site.source, '_includes/components/tabs.html')))
          .render(
            {
              'site' => site.config,
              'page' => context['page'],
              'tab_group' => tabs_id,
              'environment' => environment,
              'navtabs_id' => tabs_id
            },
            { registers: context.registers, context: context }
          )
      end
    end

    class TabBlock < Liquid::Block
      alias render_block render

      def initialize(tag_name, markup, tokens)
        super
        raise SyntaxError, "No toggle name given in #{tag_name} tag" if markup == ''

        @title = markup.strip
      end

      def render(context) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # Add support for variable titles
        path = @title.split('.')
        # 0 is the page scope, 1 is the local scope
        [0, 1].each do |k|
          next unless context.scopes[k]

          ref = context.scopes[k].dig(*path)
          @title = ref if ref
        end

        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
        environment = context.environments.first

        tabs_id = environment['navtabs-stack'].last
        environment["navtabs-#{tabs_id}"][@title] = {
          'content' => converter.convert(render_block(context)),
          'attributes' => { 'slug' => Jekyll::Utils.slugify(@title) }
        }
        ''
      end
    end
  end
end

Liquid::Template.register_tag('tab', Jekyll::KumaSpecific::TabBlock)
Liquid::Template.register_tag('tabs', Jekyll::KumaSpecific::TabsBlock)
