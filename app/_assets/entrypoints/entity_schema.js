import { createApp } from 'vue';
import EntitySchema from '~/javascripts/apps/EntitySchema.vue';
import '@kong/spec-renderer-dev/dist/style.css'

if (document.getElementById('entity-schema-app') !== null) {
  const app = createApp(EntitySchema);
  app.mount('#entity-schema-app');
}
