# frozen_string_literal: true

require 'nodo'

class CodeHighlighter < Nodo::Core # rubocop:disable Style/Documentation
  require :shiki

  script do
    <<~JS
      const highlighter = await shiki.createHighlighter({
        themes: ["catppuccin-latte", "catppuccin-mocha"],
        langs: [
          "yaml",
          "fish",
          "json",
          "powershell",
          "lua",
          "http",
          "python",
          "hcl",
          "javascript",
          "sql",
          "dockerfile",
          "go",
          "terraform",
          "nginx",
          "html",
          "ruby"
        ],
      });
    JS
  end

  function :highlight, <<~JS
    async (code, lang, id) => {
      const languageMap = {
          bash: "fish",
          sh: "fish",
          console: "fish",
          cef: "text",
          conf: "yaml",
          rego: "text"
      };
      const language = languageMap[lang] || lang;
      const html = highlighter.codeToHtml(code, {
        lang: language,
        themes: {
          light: "catppuccin-latte",
          dark: "catppuccin-mocha",
        },
        transformers: [
          {
            code(node) {
              node.properties.id = id;
            },
          },
        ],
      });
      return html;
    }
  JS
end
