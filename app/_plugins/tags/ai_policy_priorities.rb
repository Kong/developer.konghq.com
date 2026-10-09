# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  # Renders a single table of AI Policy priorities, using the priority data of
  # the latest Gateway release. Only valid AI Policy types are listed.
  class RenderAIPolicyPriorities < Liquid::Tag
    def render(context)
      @site = context.registers[:site]
      page = context.environments.first['page']

      context.stack do
        context['rows'] = rows
        Liquid::Template.parse(template(page), { line_numbers: true }).render(context)
      end
    end

    private

    def rows
      excluded = config.fetch('exclude')
      overrides = config.fetch('overrides')

      @site.data.fetch('ai_gateway_policies').filter_map do |slug, policy|
        next if excluded.include?(slug) || policy.data['published'] == false

        priority = overrides[slug] || priorities[slug]
        next if priority.nil?

        { 'title' => policy.data['name'], 'url' => policy.data['overview_url'], 'slug' => slug, 'priority' => priority }
      end.sort_by { |r| [-r['priority'], r['title']] }
    end

    def config
      @config ||= @site.data.dig('policies', 'ai-gateway', 'priority')
    end

    def priorities
      @priorities ||= @site.data.dig('plugins', 'priorities', latest_release.number.gsub('.', ''))
    end

    def latest_release
      @latest_release ||= @site.data.dig('products', 'gateway', 'releases')
                               .reject { |r| r.key?('label') }
                               .map { |r| Drops::Release.new(r) }
                               .sort.last
    end

    def template(page)
      ext = page['output_format'] == 'markdown' ? 'md' : 'html'
      File.read(File.expand_path("app/_includes/components/ai_policy_priorities.#{ext}"))
    end
  end
end

Liquid::Template.register_tag('ai_policy_priorities', Jekyll::RenderAIPolicyPriorities)
