document.addEventListener("DOMContentLoaded", function () {
  const releasesDropdown = document.getElementById("releases-dropdown");
  if (releasesDropdown) {
    releasesDropdown.addEventListener("change", function () {
      const url = releasesDropdown.value;
      if (url) {
        window.location.href = url;
      }
    });
  }

  const pluginExampleDropdown = document.getElementById(
    "plugin-example-dropdown"
  );
  if (pluginExampleDropdown) {
    pluginExampleDropdown.addEventListener("change", function () {
      const url = pluginExampleDropdown.value;
      if (url) {
        window.location.href = url;
      }
    });
  }
});
