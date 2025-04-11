# frozen_string_literal: true

module Jekyll
  class MeshGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :high

    def generate(site)
      site.data.dig('kuma_to_mesh', 'config').fetch('pages', []).each do |page_config|
        page = KumatoMesh::Page.new(site:, page_config:).to_jekyll_page
        KumatoMesh::Converter.new(page).process

        site.pages << page
      end
    end
  end
end
