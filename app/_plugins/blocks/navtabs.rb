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

      def render(context)
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
          .parse(File.read(File.join(@site.source, '_includes/components/tabs.html')))
          .render(
            {
              'site' => @site.config,
              'page' => context['page'],
              'class' => @class,
              'environment' => environment,
              'navtabs_id' => navtabs_id
            },
            { registers: context.registers, context: context }
          )
      end
    end

    class NavTabBlock < Liquid::Block
      alias render_block render

      def initialize(tag_name, markup, tokens)
        super
        raise SyntaxError, "No toggle name given in #{tag_name} tag" if markup.strip.empty?

        @title, @attributes_string = parse_markup(markup)
        @attributes = @attributes_string ? parse_attributes(@attributes_string) : {}
      end

      def parse_markup(markup)
        match = markup.match(/\s*(?:"([^"]+)"|\{\{\s*([^}]+)\s*\}\})\s*(.*)/)
        raise "Unable to parse markup: #{markup}" unless match

        # Extract the title
        title = match[1] || "{{#{match[2]}}}"

        # Extract the attributes string
        attributes_string = match[3]
        [title, attributes_string]
      end

      def parse_attributes(attributes_string)
        attributes = {}
        attributes_string.scan(/(\w+)=(?:"([^"]+)"|\{\{\s*([^}]+)\s*\}\})/) do |key, value1, value2|
          attributes[key] = value1 || "{{#{value2}}}"
        end
        attributes
      end

      def render(context)
        evaluated_title = Liquid::Template.parse(@title).render(context)
        evaluated_attributes = @attributes.transform_values { |v| Liquid::Template.parse(v).render(context) }

        # Set a default slug if not provided
        evaluated_attributes['slug'] ||= Jekyll::Utils.slugify(evaluated_title)

        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
        environment = context.environments.first

        navtabs_id = environment['navtabs-stack'].last
        environment["navtabs-#{navtabs_id}"][evaluated_title] = {
          'content' => converter.convert(render_block(context)),
          'attributes' => evaluated_attributes
        }
        ''
      end
    end
  end
end

Liquid::Template.register_tag('navtab', Jekyll::NavTabs::NavTabBlock)
Liquid::Template.register_tag('navtabs', Jekyll::NavTabs::NavTabsBlock)
