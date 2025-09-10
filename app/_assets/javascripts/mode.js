document.addEventListener("DOMContentLoaded", function () {
  const darkModeSwitches = document.querySelectorAll(".dark-mode-switch");

  darkModeSwitches.forEach((el) => {
    el.addEventListener("click", () => {
      document.documentElement.classList.add("dark");
      localStorage.setItem("mode", "dark");
      document.documentElement.style.setProperty("color-scheme", "dark");
    });
  });

  const lightModeSwitches = document.querySelectorAll(".light-mode-switch");

  lightModeSwitches.forEach((el) => {
    el.addEventListener("click", () => {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("mode", "");
      document.documentElement.style.setProperty("color-scheme", "light");
    });
  });
});
