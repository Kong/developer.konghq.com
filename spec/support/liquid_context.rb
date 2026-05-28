# frozen_string_literal: true

SiteDouble = Struct.new(:source, :config, :data, :includes_load_paths, keyword_init: true)

def build_site_double(source: nil, config: {}, data: {})
  source_path = source || File.join(PROJECT_ROOT, 'app')
  SiteDouble.new(
    source: source_path,
    config: { 'output_format' => 'html' }.merge(config),
    data: data,
    includes_load_paths: [File.join(source_path, '_includes')]
  )
end

def build_liquid_context(site: nil, page: {}, locals: {})
  site_obj = site || build_site_double
  liquid_page = { 'path' => 'test/page.md', 'output_format' => 'html' }.merge(page)

  Liquid::Context.new(
    [{ 'page' => liquid_page }.merge(locals)],
    {},
    { site: site_obj, page: liquid_page },
    true
  )
end
