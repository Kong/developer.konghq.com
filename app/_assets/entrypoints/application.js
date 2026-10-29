// To see this message, follow the instructions for your Ruby framework.
//
// When using a plain API, perhaps it's better to generate an HTML entrypoint
// and link to the scripts and stylesheets, and let Vite transform it.

// Example: Import a stylesheet in <sourceCodeDir>/index.css
import "~/stylesheets/index.css";

import { datadogRum } from "@datadog/browser-rum";
import { mount } from "pele";
import icons from "@/javascripts/diagram-icons";
import Dropdowns from "@/javascripts/components/dropdown";
import EntityExample from "@/javascripts/components/entity_example";
import Tabs from "@/javascripts/components/tabs";
import TopNav from "@/javascripts/components/top_nav";
import ToggleSwitchManager from "@/javascripts/components/switch";
import "@/javascripts/anchor_links";
import "@/javascripts/accordion";
import "@/javascripts/banner";
import "@/javascripts/how_to";
import "@/javascripts/mode";
import "@/javascripts/dropdowns";
import "@/javascripts/toc";
import "@/javascripts/search_modal";
import "@/javascripts/mesh_service_switcher";
import "@/javascripts/feedback";
import "@/javascripts/clipboard_copy";
import "@/javascripts/llm_dropdown";
import "@/javascripts/collapsible_code";
import "@/javascripts/expandable_image";
import "@/javascripts/tooltip";
import "@/javascripts/arcade";
import "@github/clipboard-copy-element";

document.addEventListener("DOMContentLoaded", function () {
  new TopNav();
  new EntityExample();
  new Tabs();
  new Dropdowns();
  new ToggleSwitchManager();
});

// if (import.meta.env.PROD) {
//   datadogRum.init({
//     applicationId: "cd1c65ad-3e37-401e-8f35-4cb60b9e8b31",
//     clientToken: "pub979ff3cfe46e8ced39f17c739a7b9388",
//     // `site` refers to the Datadog site parameter of your organization
//     // see https://docs.datadoghq.com/getting_started/site/
//     site: "datadoghq.com",
//     service: "developer.konghq.com",
//     env: "prod",
//     // Specify a version number to identify the deployed version of your application in Datadog
//     // version: '1.0.0',
//     sessionSampleRate: 100,
//     sessionReplaySampleRate: 20,
//     defaultPrivacyLevel: "mask-user-input",
//   });
// }

function resolveDiagramIcon(token) {
  const name = token.replace(/^fa:fa-/, "");
  return icons[name] ?? null;
}

for (const el of document.querySelectorAll("pre.mermaid")) {
  mount(el, el.textContent.trim(), {
    zoom: true,
    icons: resolveDiagramIcon,
  });
}

window.addEventListener("load", () => {
  const hash = window.location.hash;
  if (hash && !document.getElementById("api-spec")) {
    const escapedHash = CSS.escape(hash.slice(1));
    // Give time for collapsibles to expand/diagrams to render
    setTimeout(() => {
      const el = document.querySelector(`#${escapedHash}`);
      if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 300); // delay for layout to settle
  }
});
