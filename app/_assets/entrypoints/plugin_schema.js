import { createApp } from "vue";
import PluginSchema from "~/javascripts/apps/PluginSchema.vue";
import "@kong/spec-renderer-dev/dist/style.css";

if (document.getElementById("schema") !== null) {
  const app = createApp(PluginSchema);
  app.mount("#schema");
}
