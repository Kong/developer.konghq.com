import { createHighlighter } from "shiki";
let language = process.argv[2] || "text";
let codeSnippetId = process.argv[3];

// The spec-renderer uses `fish` for bash/sh
const languageMap = {
  bash: "fish",
  sh: "fish",
  console: "fish",
  cef: "text",
  conf: "yaml",
};

async function main() {
  let code = "";
  process.stdin.setEncoding("utf8");

  try {
    for await (const chunk of process.stdin) {
      code += chunk;
    }

    language = languageMap[language] || language;

    const highlighter = await createHighlighter({
      themes: ["catppuccin-latte", "catppuccin-mocha"],
      langs: [
        "yaml",
        "fish",
        "json",
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
      ],
    });

    const html = highlighter.codeToHtml(code, {
      lang: language,
      themes: {
        light: "catppuccin-latte",
        dark: "catppuccin-mocha",
      },
      transformers: [
        {
          code(node) {
            node.properties.id = codeSnippetId;
          },
        },
      ],
    });

    console.log(html);
  } catch (error) {
    console.error(error.message, { to: process.stderr });
    process.exit(1);
  }
}

main();
