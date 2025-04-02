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

  document
    .querySelectorAll(".copy-code-snippet, pre > code")
    .forEach(function (element) {
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
      if (
        !snippet.classList.contains("copy-code-snippet") &&
        snippet.classList.contains("no-copy-code")
      ) {
        return;
      }
      snippet.classList.add("copy-code-snippet");

      const action = document.createElement("div");
      action.className = "copy-action";
      action.innerHTML = `
      <svg width="20" height="20" viewBox="0 0 24 24" fill="#BFCAD5" xmlns="http://www.w3.org/2000/svg">
        <path d="M5 22C4.45 22 3.97917 21.8042 3.5875 21.4125C3.19583 21.0208 3 20.55 3 20V6H5V20H16V22H5ZM9 18C8.45 18 7.97917 17.8042 7.5875 17.4125C7.19583 17.0208 7 16.55 7 16V4C7 3.45 7.19583 2.97917 7.5875 2.5875C7.97917 2.19583 8.45 2 9 2H18C18.55 2 19.0208 2.19583 19.4125 2.5875C19.8042 2.97917 20 3.45 20 4V16C20 16.55 19.8042 17.0208 19.4125 17.4125C19.0208 17.8042 18.55 18 18 18H9ZM9 16H18V4H9V16Z" fill="#BFCAD5"/>
      </svg>
    `;

      snippet.appendChild(action);

      const successInfo = document.createElement("div");
      successInfo.className = "copy-code-success-info";
      successInfo.textContent = "Copied to clipboard!";
      successInfo.classList.add("scale-0");

      snippet.appendChild(successInfo);

      successInfo.addEventListener("transitionend", function () {
        successInfo.classList.remove("opacity-100", "scale-1");
        successInfo.classList.add("scale-0");
      });
      action.addEventListener("click", function (event) {
        const successInfo = event.currentTarget.parentElement.querySelector(
          ".copy-code-success-info"
        );
        copyInput.value =
          snippet.dataset.copyCode ||
          snippet
            .querySelector("code")
            .textContent.replace(/^ /gim, "")
        copyInput.select();
        document.execCommand("copy");
        successInfo.classList.remove("scale-0");
        successInfo.classList.add("scale-1", "opacity-100");
      });
    });
});
