function toggleTocLinkClasses(link, isActive) {
  const activeClasses = ["tab-button__vertical--active"];

  if (isActive) {
    link.classList.add(...activeClasses);
  } else {
    link.classList.remove(...activeClasses);
  }
}

window.addEventListener("scroll", () => {
  const anchors = document.querySelectorAll("a.header-link");
  const scrollToLinks = document.querySelectorAll("a.scroll-to");
  const navHeight = document.getElementById("header-nav").offsetHeight;

  if (!anchors.length || !scrollToLinks.length) {
    return;
  }

  let activeSet = false;

  scrollToLinks.forEach((link) => toggleTocLinkClasses(link, false));

  // Convert NodeList to Array and reverse it
  const anchorsArray = Array.from(anchors).reverse();

  for (const element of anchorsArray) {
    const elementTop = element.getBoundingClientRect().top + window.scrollY;

    // window top + header section + extra padding
    if (window.scrollY + navHeight + 20 >= elementTop) {
      const matchingLink = document.querySelector(
        `a.scroll-to[href$="${element.getAttribute("href")}"]`
      );
      if (matchingLink) {
        toggleTocLinkClasses(matchingLink, true);
        activeSet = true;
      }
      break;
    }
  }

  if (!activeSet) {
    toggleTocLinkClasses(scrollToLinks[0], true);
  }
});
