# frozen_string_literal: true

module Jekyll
  class RenderKonnectChangelog < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @page = @context.environments.first['page']
      site = context.registers[:site]
      changelog = Drops::KonnectChangelog.new(site:)

      context.stack do
        context['changelog'] = changelog
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'rss'
        File.read(File.expand_path('app/_includes/components/konnect_changelog.xml'))
      else
        File.read(File.expand_path('app/_includes/components/konnect_changelog.html'))
      end
    end
  end
end

Liquid::Template.register_tag('konnect_changelog', Jekyll::RenderKonnectChangelog)
