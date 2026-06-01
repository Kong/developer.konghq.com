# frozen_string_literal: true

def build_liquid_context(page: {}, locals: {})
  liquid_page = { 'path' => 'test/page.md', 'output_format' => 'html' }.merge(page)

  Liquid::Context.new(
    [{ 'page' => liquid_page }.merge(locals)],
    {},
    { site: JekyllSite.instance, page: liquid_page },
    true
  )
end

def render_liquid(source, page: {}, locals: {})
  Liquid::Template.parse(source).render!(
    build_liquid_context(page: page, locals: locals)
  )
end
