  window.addEventListener("scroll", () => {
    const anchors = document.querySelectorAll("a.header-link");
    const scrollToLinks = document.querySelectorAll("a.scroll-to");
    const navHeight = document.getElementById('header-nav').offsetHeight;
    const activeClasses = ['border-l-2', 'border-brand'];

    if (!anchors.length || !scrollToLinks.length) {
      return;
    }

    let activeSet = false;

    scrollToLinks.forEach(link => link.parentElement.classList.remove(...activeClasses));

    // Convert NodeList to Array and reverse it
    const anchorsArray = Array.from(anchors).reverse();

    for (const element of anchorsArray) {
      const elementTop = element.getBoundingClientRect().top + window.scrollY;

      // window top + header section + extra padding
      if (window.scrollY + navHeight + 20 >= elementTop) {
        const matchingLink = document.querySelector(`a.scroll-to[href$="${element.getAttribute("href")}"]`);
        if (matchingLink) {
          matchingLink.parentElement.classList.add(...activeClasses);
          activeSet = true;
        }
        break;
      }
    };

    if (!activeSet) {
      scrollToLinks[0].parentElement.classList.add(...activeClasses);
    }
  });