import { createApp } from "vue";
import Feedback from "~/javascripts/apps/Feedback.vue";
import "@kong/spec-renderer/dist/style.css";

if (document.getElementById("feedback") !== null) {
  const app = createApp(Feedback);
  app.mount("#feedback");
}
