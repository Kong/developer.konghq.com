# frozen_string_literal: true

module Jekyll
  module KumaSpecific
    class JsonSchema < Liquid::Tag # rubocop:disable Style/Documentation
      def initialize(tag_name, markup, options)
        super

        @name, *params_list = @markup.split(' ')
        @params = { 'type' => 'policy' }
        params_list.each do |item|
          sp = item.split('=')
          @params[sp[0]] = sp[1] unless sp[1] == ''
        end
      end

      def render(context)
        page = context.environments.first['page']

        # Mark this page as having a plugin schema to load the relevant JS
        page['plugin_schema'] = true

        release = page['release']
        schema_file = Drops::MeshPolicies::SchemaFile.new(release:, type: @params['type'], name: @name)

        context.stack do
          context['schema'] = schema_file
          Liquid::Template.parse(template).render(context)
        end
      end

      private

      def template
        @template ||= File.read(File.expand_path('app/_includes/components/kuma_specific/json_schema.html'))
      end
    end
  end
end

Liquid::Template.register_tag('json_schema', Jekyll::KumaSpecific::JsonSchema)
