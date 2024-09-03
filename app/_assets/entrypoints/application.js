// To see this message, follow the instructions for your Ruby framework.
//
// When using a plain API, perhaps it's better to generate an HTML entrypoint
// and link to the scripts and stylesheets, and let Vite transform it.

// Example: Import a stylesheet in <sourceCodeDir>/index.css
import '~/stylesheets/index.css'
import '~/stylesheets/syntax_highlighting.css'
import '~/stylesheets/copy_code_snippet.css'

import EntityExample from '@/javascripts/components/entity_example';
import PluginConfigExample from '@/javascripts/components/plugin_config_example';
import Tabs from '@/javascripts/components/tabs';
import '@/javascripts/anchor_links';
import '@/javascripts/copy_code_snippet';
import '@/javascripts/toc';

document.addEventListener('DOMContentLoaded', function () {
  new EntityExample();
  new PluginConfigExample();
  new Tabs();
});