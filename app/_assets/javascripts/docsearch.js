import docsearch from "@docsearch/js";

import "@docsearch/css";

docsearch({
  container: "#docsearch",
  appId: "Z2JDSBZWKU",
  indexName: "kongdeveloper",
  apiKey: "7eaf59d4529f8b3bb44e5a8556aac227",
  maxResultsPerGroup: 10,
  disableUserPersonalization: true,
  transformItems(items) {
    return items.map((item) => {
      const urlObj = new URL(item.url);
      const path = `${urlObj.pathname}${urlObj.hash}`;

      const content = item.content || item.description;
      let type;
      if (item.content) {
        type = "content";
      } else if (hierarchy.lvl4 !== null) {
        type = "lvl4";
      } else if (hierarchy.lvl3 !== null) {
        type = "lvl3";
      } else if (hierarchy.lvl2 !== null) {
        type = "lvl2";
      } else if (hierarchy.lvl1 !== null) {
        type = "lvl1";
      }
      return { ...item, url: path, content, type };
    });
  },
  searchParameters: {
    attributesToRetrieve: ["*"],
  },
});
