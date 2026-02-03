# frozen_string_literal: true

module Jekyll
  class RenderKongConf < Liquid::Tag # rubocop:disable Style/Documentation
    def render(context)
      @page = context.environments.first['page']

      context.stack do
        context['config'] = Drops::KongConf.new
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= if @page['output_format'] == 'markdown'
                      File.read(File.expand_path('app/_includes/components/kong_conf.md'))
                    else
                      File.read(File.expand_path('app/_includes/components/kong_conf.html'))
                    end
    end
  end
end

Liquid::Template.register_tag('kong_conf', Jekyll::RenderKongConf)
