// To see this message, follow the instructions for your Ruby framework.
//
// When using a plain API, perhaps it's better to generate an HTML entrypoint
// and link to the scripts and stylesheets, and let Vite transform it.

// Example: Import a stylesheet in <sourceCodeDir>/index.css
import "~/stylesheets/index.css";

import mermaid from "mermaid";
import EntityExample from "@/javascripts/components/entity_example";
import Tabs from "@/javascripts/components/tabs";
import "@/javascripts/anchor_links";
import "@/javascripts/accordion";
import "@/javascripts/copy_code_snippet";
import "@/javascripts/how_to";
import "@/javascripts/mode";
import "@/javascripts/dropdowns";
import "@/javascripts/toc";
import "@/javascripts/search_modal";
import "@/javascripts/mesh_service_switcher";

document.addEventListener("DOMContentLoaded", function () {
  new EntityExample();
  new Tabs();
});

mermaid.initialize({
  startOnLoad: true,
  theme: "base",
  themeVariables: {
    primaryColor: "#fff",
    primaryBorderColor: "#4a86e8",
    primaryTextColor: "#495c64",
    secondaryColor: "#fff",
    secondaryTextColor: "#5096f2",
    tertiaryBorderColor: "#AAB4BB",
    edgeLabelBackground: "#fff",
    fontFamily: '"Inter", system-ui, sans-serif',
    fontSize: "15px",
    lineColor: "#99b0c0",
    activationBorderColor: "#c2d4e0",
    sequenceNumberColor: "#fff",
  },
});
