import { createApp } from "vue";
import PluginSchema from "~/javascripts/apps/PluginSchema.vue";
import "@kong/spec-renderer/dist/style.css";

// For kuma files
if (document.getElementById("plugin-schema") !== null) {
  const app = createApp(PluginSchema);
  app.mount("#plugin-schema");
} else if (document.getElementById("schema") !== null) {
  const app = createApp(PluginSchema);
  app.mount("#schema");
}
