import pkg from "broken-link-checker";
import { readFileSync } from "node:fs";
const { SiteChecker } = pkg;

export default function (options) {
  return new Promise((resolve, reject) => {
    const brokenLinks = new Set();
    const otherErrors = new Set();
    let processed = 0;
    const outputInterval = 1000;
    const ignoredPlaceholders = JSON.parse(
      readFileSync("./config/ignored_placeholder_paths.json")
    );

    const siteChecker = new SiteChecker(
      {
        honorRobotExclusions: false,
        excludedKeywords: options.excluded,
        maxSocketsPerHost: 128,
        cacheResponses: true,
      },
      {
        link: (result) => {
          processed++;
          if (processed % outputInterval === 0) {
            console.log(`Processed ${processed} links`);
          }

          // Ignore placeholder links
          for (const link of ignoredPlaceholders) {
            if (result.url.resolved.match(link)) {
              return;
            }
          }

          if (result.broken) {
            const linkResult = {
              page: result.base.resolved,
              text: result.html.text,
              target: result.url.resolved,
              reason: result.brokenReason,
            };
            if (result.brokenReason === "HTTP_404") {
              brokenLinks.add(linkResult);
            } else {
              otherErrors.add(linkResult);
            }
          }
        },
        end: () => {
          resolve({
            brokenLinks: [...brokenLinks],
            otherErrors: [...otherErrors],
          });
        },
      }
    );

    console.log("Starting check...");
    siteChecker.enqueue(options.host);
  });
}
