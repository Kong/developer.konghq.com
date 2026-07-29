# frozen_string_literal: true

def build_page(url:, llm_title: nil, description: nil, data: {})
  title         = llm_title || url
  desc          = description
  liquid_hash   = { 'llm_title' => title, 'url' => url, 'description' => desc }

  Object.new.tap do |p|
    p.define_singleton_method(:url)      { url }
    p.define_singleton_method(:data)     { data }
    p.define_singleton_method(:[])       { |key| liquid_hash[key] }
    p.define_singleton_method(:to_liquid) { liquid_hash }
  end
end
