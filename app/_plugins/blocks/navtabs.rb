# frozen_string_literal: true

require 'erb'
require 'securerandom'

module Jekyll
  module NavTabs
    class NavTabsBlock < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
        @class = markup.strip
      end

      def render(context) # rubocop:disable Metrics/MethodLength
        navtabs_id = SecureRandom.uuid
        environment = context.environments.first
        @site = context.registers[:site]

        environment["navtabs-#{navtabs_id}"] = {}
        environment['navtabs-stack'] ||= []
        environment['navtabs-stack'].push(navtabs_id)

        super

        environment['navtabs-stack'].pop
        environment['additional_classes'] = ''

        Liquid::Template
          .parse(File.read('app/_includes/components/tabs.html'))
          .render(
            {
              'site' => @site.config, 'page' => @page,
              'class' => @class, 'environment' => environment, 'navtabs_id' => navtabs_id,
            },
            { registers: context.registers, context: @context }
          )
      end
    end

    class NavTabBlock < Liquid::Block
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

        navtabs_id = environment['navtabs-stack'].last
        environment["navtabs-#{navtabs_id}"][@title] = converter.convert(render_block(context))
      end
    end
  end
end

Liquid::Template.register_tag('navtab', Jekyll::NavTabs::NavTabBlock)
Liquid::Template.register_tag('navtabs', Jekyll::NavTabs::NavTabsBlock)
