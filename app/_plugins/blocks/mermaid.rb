# frozen_string_literal: true

module Jekyll
  class RenderMermaid < Liquid::Block
    def render(context)
      text = super

      "<pre class='mermaid'> #{text}  </pre>"
    end
  end
end

Liquid::Template.register_tag('mermaid', Jekyll::RenderMermaid)
