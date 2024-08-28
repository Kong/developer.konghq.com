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

    const action = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    action.setAttribute("viewBox", "0 0 115.77 122.88");
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("d", "M89.62 13.96v7.73h12.19c3.85 0 7.34 1.57 9.86 4.1 2.5 2.51 4.06 5.98 4.07 9.82v73.28c-0.01 3.84-1.57 7.33-4.1 9.85-2.51 2.5-5.98 4.07-9.82 4.07H40.1c-3.84-0.01-7.34-1.57-9.86-4.1-2.5-2.51-4.06-5.98-4.07-9.82V92.51H13.96c-3.84-0.01-7.34-1.57-9.86-4.1-2.5-2.51-4.06-5.98-4.07-9.82V13.96c0.01-3.85 1.58-7.34 4.1-9.86 2.51-2.5 5.98-4.07 9.82-4.07h61.7c3.85 0.01 7.34 1.57 9.86 4.1 2.5 2.51 4.06 5.98 4.07 9.82v7.73zM79.04 21.69v-7.73c0-0.91-0.39-1.75-1.01-2.37-0.61-0.61-1.46-1-2.37-1H13.96c-0.91 0-1.75 0.39-2.37 1.01-0.61 0.61-1 1.46-1 2.37v64.59c0 0.91 0.39 1.75 1.01 2.37 0.61 0.61 1.46 1 2.37 1h12.19V35.65c0.01-3.85 1.58-7.34 4.1-9.86 2.51-2.5 5.98-4.06 9.82-4.07h40.78zM105.18 108.92V35.65c0-0.91-0.39-1.75-1.01-2.37-0.61-0.61-1.46-1-2.37-1H40.1c-0.91 0-1.75 0.39-2.37 1.01-0.61 0.61-1 1.46-1 2.37v73.27c0 0.91 0.39 1.75 1.01 2.37 0.61 0.61 1.46 1 2.37 1h61.7c0.91 0 1.75-0.39 2.37-1.01 0.61-0.61 1-1.46 1-2.37z");
    action.appendChild(path);

    action.classList.add("copy-action");
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
      successInfo.style.top = `${rect.top - rect.height / 2}px`;
      successInfo.style.left = `${rect.left + rect.width / 2}px`;
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
