const anchorForId = (id) => {
    const anchor = document.createElement("a");
    anchor.classList.add("header-link");
    anchor.href = `#${id}`;
    anchor.ariaLabel = 'Anchor';
    return anchor;
  };

  document.addEventListener("DOMContentLoaded", () => {
    const headers = document.querySelectorAll("h1, h2, h3, h4, h5, h6");

    headers.forEach(header => {
      if (header.id) {
        header.prepend(anchorForId(header.id));
      }
    });
  });