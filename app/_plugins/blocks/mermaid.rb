# frozen_string_literal: true

require 'cgi'

module Jekyll
  class RenderMermaid < Liquid::Block
    MARKDOWN_FENCE = "```mermaid"

    def render(context)
      source = super

      return markdown_diagram(source) if markdown?(context)

      %(<pre class="mermaid">#{mounted_source(source)}</pre>)
    end

    private

    def mounted_source(source)
      CGI.escapeHTML(CGI.unescapeHTML(source.to_s)).strip
    end

    def markdown_diagram(source)
      "#{MARKDOWN_FENCE}\n#{CGI.unescapeHTML(source.to_s).strip}\n```\n"
    end

    def markdown?(context)
      page(context)['output_format'] == 'markdown'
    end

    def page(context)
      context.registers[:page] || {}
    end
  end
end

Liquid::Template.register_tag('mermaid', Jekyll::RenderMermaid)
