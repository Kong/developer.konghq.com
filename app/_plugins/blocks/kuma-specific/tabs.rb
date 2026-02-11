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
        @site = context.registers[:site]
        @page = context.environments.first['page']
        environment = context.environments.first
        environment["navtabs-#{tabs_id}"] = {}
        environment['navtabs-stack'] ||= []
        environment['navtabs-stack'].push(tabs_id)

        super

        environment['navtabs-stack'].pop
        environment['additional_classes'] = @class

        context.stack do
          context['tab_group'] = tabs_id
          context['environment'] = environment
          context['navtabs_id'] = tabs_id
          context['heading_level'] = parse_heading_level(context)
          Liquid::Template
            .parse(template)
            .render(context)
        end
      end

      def template
        if @page['output_format'] == 'markdown'
          File.read(File.join(@site.source, '_includes/components/tabs.md'))
        else
          File.read(File.join(@site.source, '_includes/components/tabs.html'))
        end
      end

      def parse_heading_level(context)
        Jekyll::ClosestHeading.new(@page, 'tabs').level + 1
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

        contents = super

        environment = context.environments.first

        tabs_id = environment['navtabs-stack'].last
        environment["navtabs-#{tabs_id}"][@title] = {
          'content' => block_content(context, contents),
          'attributes' => { 'slug' => Jekyll::Utils.slugify(@title) }
        }
        ''
      end

      def block_content(context, contents)
        page = context.environments.first['page']

        if page['output_format'] == 'markdown'
          contents
        else
          site = context.registers[:site]
          converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
          converter.convert(render_block(context))
        end
      end
    end
  end
end

Liquid::Template.register_tag('tab', Jekyll::KumaSpecific::TabBlock)
Liquid::Template.register_tag('tabs', Jekyll::KumaSpecific::TabsBlock)
