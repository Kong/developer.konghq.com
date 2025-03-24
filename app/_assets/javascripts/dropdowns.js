document.addEventListener("DOMContentLoaded", () => {
  document
    .querySelectorAll(".releases-dropdown")
    .forEach((releasesDropdown) => {
      if (releasesDropdown) {
        releasesDropdown.addEventListener("change", () => {
          const url = releasesDropdown.value;
          if (url) {
            window.location.href = url;
          }
        });
      }
    });

  const pluginExampleDropdown = document.getElementById(
    "plugin-example-dropdown"
  );
  if (pluginExampleDropdown) {
    pluginExampleDropdown.addEventListener("change", () => {
      const url = pluginExampleDropdown.value;
      if (url) {
        window.location.href = url;
      }
    });
  }
});
