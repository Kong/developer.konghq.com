// To see this message, follow the instructions for your Ruby framework.
//
// When using a plain API, perhaps it's better to generate an HTML entrypoint
// and link to the scripts and stylesheets, and let Vite transform it.

// Example: Import a stylesheet in <sourceCodeDir>/index.css
import '~/stylesheets/index.css'
import '~/stylesheets/core.css'

import EntityExample from '@/javascripts/components/entity_example';

document.addEventListener('DOMContentLoaded', function () {
  new EntityExample();
});
