/**
 * Copy code snippet support
 *
 * By default copy code is enabled for all code blocks. If you want disable it for specific snippet use class 'no-copy-code'
 * ```bash
 * $ curl -X GET http://kong:8001/basic-auths
 * ```
 * {: .no-copy-code }
 *
 */
document.addEventListener("DOMContentLoaded", function () {
  const copyInput = document.createElement("textarea");
  copyInput.id = "copy-code-input";
  document.body.appendChild(copyInput);

  document.querySelectorAll(".copy-code-snippet, pre > code").forEach(function (element) {
    function findSnippetElement() {
      let snippet = element.closest(".highlighter-rouge");
      if (snippet) return snippet;

      snippet = element.closest(".highlight");
      if (snippet) return snippet;

      snippet = element.closest("pre");
      if (snippet) return snippet;

      return element;
    }

    const snippet = findSnippetElement();
    if (!snippet.classList.contains("copy-code-snippet") && snippet.classList.contains("no-copy-code")) {
      return;
    }
    snippet.classList.add("copy-code-snippet");

    const action = document.createElement("i");
    action.className = "copy-action fa fa-copy";
    action.addEventListener("click", function () {
      if (document.getElementById("copy-code-success-info")) {
        return;
      }

      copyInput.value =
        snippet.dataset.copyCode ||
        snippet.querySelector("code").textContent.replace(/^ /gim, "").replace(/^\s*\$\s*/gim, "");
      copyInput.select();
      document.execCommand("copy");

      const rect = action.getBoundingClientRect();
      const successInfo = document.createElement("div");
      successInfo.id = "copy-code-success-info";
      successInfo.textContent = "Copied to clipboard!";
      successInfo.style.top = `${rect.top - action.offsetHeight / 2}px`;
      successInfo.style.left = `${rect.left + action.offsetWidth / 2}px`;
      successInfo.style.opacity = "1";

      setTimeout(function () {
        successInfo.style.transition = "opacity 0.5s";
        successInfo.style.opacity = "0";
        successInfo.addEventListener("transitionend", function () {
          successInfo.remove();
        });
      }, 1000);
      document.body.appendChild(successInfo);
    });
    snippet.appendChild(action);
  });
});
