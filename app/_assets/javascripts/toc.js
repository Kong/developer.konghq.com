function toggleTocLinkClasses(link, isActive) {
  const activeClasses = ['border-l-2', 'border-brand'];
  const activeLinkClasses = ['text-primary', '-ml-0.5'];

  if (isActive) {
      link.classList.add(...activeLinkClasses);
      link.classList.remove('text-secondary');
      link.parentElement.classList.add(...activeClasses);
  } else {
      link.classList.add('text-secondary');
      link.classList.remove(...activeLinkClasses);
      link.parentElement.classList.remove(...activeClasses);
  }
}

window.addEventListener("scroll", () => {
    const anchors = document.querySelectorAll("a.header-link");
    const scrollToLinks = document.querySelectorAll("a.scroll-to");
    const navHeight = document.getElementById('header-nav').offsetHeight;

    if (!anchors.length || !scrollToLinks.length) {
      return;
    }

    let activeSet = false;

    scrollToLinks.forEach(link => toggleTocLinkClasses(link, false));

    // Convert NodeList to Array and reverse it
    const anchorsArray = Array.from(anchors).reverse();

    for (const element of anchorsArray) {
      const elementTop = element.getBoundingClientRect().top + window.scrollY;

      // window top + header section + extra padding
      if (window.scrollY + navHeight + 20 >= elementTop) {
        const matchingLink = document.querySelector(`a.scroll-to[href$="${element.getAttribute("href")}"]`);
        if (matchingLink) {
          toggleTocLinkClasses(matchingLink, true);
          activeSet = true;
        }
        break;
      }
    };

    if (!activeSet) {
      toggleTocLinkClasses(scrollToLinks[0], true);
    }
  });
