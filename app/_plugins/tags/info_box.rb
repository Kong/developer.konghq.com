# frozen_string_literal: true

module Jekyll
  class RenderInfoBox < Liquid::Tag
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      info_box = Drops::InfoBox::Base.make_for(page: @page, site: @site)

      context.stack do
        context['info_box'] = info_box
        Liquid::Template
          .parse(File.read(info_box.template_file))
          .render(context)
      end
    end
  end
end

Liquid::Template.register_tag('info_box', Jekyll::RenderInfoBox)
