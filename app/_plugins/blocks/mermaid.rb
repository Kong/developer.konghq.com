# frozen_string_literal: true

require 'cgi'

module Jekyll
  class RenderMermaid < Liquid::Block
    def render(context)
      source = super

      %(<pre class="mermaid">#{mounted_source(source)}</pre>)
    end

    private

    def mounted_source(source)
      CGI.escapeHTML(CGI.unescapeHTML(source.to_s)).strip
    end
  end
end

Liquid::Template.register_tag('mermaid', Jekyll::RenderMermaid)
