# frozen_string_literal: true

require 'erb'
require 'securerandom'

module Jekyll
  module NavTabs
    class NavTabsBlock < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super

        @tab_group = markup.strip
      end

      def render(context)
        navtabs_id = SecureRandom.uuid
        environment = context.environments.first
        @site = context.registers[:site]
        @page = context.environments.first['page']

        if @tab_group.empty?
          raise ArgumentError,
                "Missing `tab_group` for {% navtabs %} in #{@page['path']}. Syntax is: {% navtabs \"tab_group\" %}"
        end

        environment["navtabs-#{navtabs_id}"] = {}
        environment['navtabs-stack'] ||= []
        environment['navtabs-stack'].push(navtabs_id)

        super

        environment['navtabs-stack'].pop
        environment['additional_classes'] = ''

        if @tab_group.include?('"')
          group = @tab_group.delete('"')
        else
          keys = @tab_group.split('.')
          group = keys.reduce(context) { |c, key| c[key] } || @tab_group
        end
        context.stack do
          context['tab_group'] = group
          context['environment'] = environment
          context['navtabs_id'] = navtabs_id
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
        environment = context.environments.first

        navtabs_id = environment['navtabs-stack'].last
        environment["navtabs-#{navtabs_id}"][evaluated_title] = {
          'content' => block_content(context),
          'attributes' => evaluated_attributes
        }
        ''
      end

      def block_content(context)
        page = context.environments.first['page']
        if page['output_format'] == 'markdown'
          render_block(context)
        else
          site = context.registers[:site]
          converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
          converter.convert(render_block(context))
        end
      end
    end
  end
end

Liquid::Template.register_tag('navtab', Jekyll::NavTabs::NavTabBlock)
Liquid::Template.register_tag('navtabs', Jekyll::NavTabs::NavTabsBlock)
