function toggleTocLinkClasses(link, isActive, activeClass) {
  if (isActive) {
    link.classList.add(activeClass);
  } else {
    link.classList.remove(activeClass);
  }
}

window.addEventListener("scroll", () => {
  const activeClass = "tab-button__vertical--active";
  const anchors = document.querySelectorAll("a.link-anchor");
  const scrollToLinks = document.querySelectorAll("a.scroll-to");
  const navHeight = document.getElementById("header-nav").offsetHeight;

  if (!anchors.length || !scrollToLinks.length) {
    return;
  }

  let activeSet = document.querySelectorAll(
    `a.scroll-to.${activeClass}`
  ).length;

  // Convert NodeList to Array and reverse it
  const anchorsArray = Array.from(anchors).reverse();

  for (const element of anchorsArray) {
    const elementTop = element.getBoundingClientRect().top + window.scrollY;

    // window top + header section + extra padding
    if (window.scrollY + navHeight + 30 >= elementTop) {
      const matchingLink = document.querySelector(
        `a.scroll-to[href$="${element.getAttribute("href")}"]`
      );
      if (matchingLink) {
        toggleTocLinkClasses(matchingLink, true, activeClass);
        scrollToLinks.forEach(
          (link) =>
            link !== matchingLink &&
            toggleTocLinkClasses(link, false, activeClass)
        );
        activeSet = true;
      }
      break;
    }
  }

  if (!activeSet) {
    toggleTocLinkClasses(scrollToLinks[0], true);
  }
});
