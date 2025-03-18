document.addEventListener("DOMContentLoaded", function () {
  const select = document.getElementById("releases-dropdown");
  if (select) {
    select.addEventListener("change", function () {
      const url = select.value;
      if (url) {
        window.location.href = url;
      }
    });
  }
});
