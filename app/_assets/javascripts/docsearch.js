import docsearch from "@docsearch/js";

import "@docsearch/css";

docsearch({
  container: "#docsearch",
  appId: "Z2JDSBZWKU",
  indexName: "kongdeveloper",
  apiKey: "7eaf59d4529f8b3bb44e5a8556aac227",
  transformItems(items) {
    return items.map((item) => {
      const urlObj = new URL(item.url);
      const path = `${urlObj.pathname}${urlObj.hash}`;
      return { ...item, url: path };
    });
  },
});
