import pkg from "broken-link-checker";
import { readFileSync } from "node:fs";
import { resolve as resolvePath } from "path";

const { HtmlUrlChecker } = pkg;

export default function (urls, opts) {
  return new Promise((resolve) => {
    const brokenLinks = new Set();
    const otherErrors = new Set();
    const ignoredTargets = JSON.parse(
      readFileSync(resolvePath("./config/ignored_targets.json"), "utf-8")
    );
    const ignoredPlaceholders = JSON.parse(
      readFileSync("./config/ignored_placeholder_paths.json")
    );

    const checker = new HtmlUrlChecker(
      {
        honorRobotExclusions: false,
        excludedKeywords: ignoredTargets,
        maxSocketsPerHost: 64,
        requestMethod: "get",
        cacheResponses: true,
      },
      {
        link: (result, data) => {
          if (result.broken) {
            // Ignore any broken links in the opts.ignore list
            for (const link of opts.ignore) {
              if (result.url.resolved.match(link)) {
                return;
              }
            }
            // Ignore placeholder links
            for (const link of ignoredPlaceholders) {
              if (result.url.resolved.match(link)) {
                return;
              }
            }
            // Don't report on the "Edit this Page" links for forks as
            // they'll always be broken
            if (
              opts.skipEditLink &&
              result.url.resolved.match(
                /.*github\.com\/Kong\/developer\.konghq\.com\/edit\/.*/
              )
            ) {
              return;
            }

            const linkResult = {
              page: result.base.resolved,
              source: data.source,
              text: result.html.text,
              target: result.url.resolved,
              reason: result.brokenReason,
            };

            // Keep a separate list for links that failed with a status code other than 404
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

    for (const url of urls) {
      checker.enqueue(url.url, url);
    }
  });
}
