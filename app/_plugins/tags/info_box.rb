# frozen_string_literal: true

module Jekyll
  class RenderInfoBox < Liquid::Tag
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      info_box = Drops::InfoBox::Base.make_for(page: @page)

      rendered_content = Liquid::Template
        .parse(File.read(info_box.template_file))
        .render(
          { 'site' => @site.config, 'page' => @page, 'include' => { 'info_box' => info_box } },
          { registers: @context.registers, context: @context }
        )
    end
  end
end

Liquid::Template.register_tag('info_box', Jekyll::RenderInfoBox)
