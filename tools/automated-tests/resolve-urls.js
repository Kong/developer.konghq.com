import { glob } from "tinyglobby";
import { testeableUrlsFromFiles } from "./instructions-file.js";
import { collectHowToFiles } from "./collect-how-to-files.mjs";

/**
 * Decide which how-to URLs an instruction-file run must cover.
 *
 * Four modes, in precedence order:
 *   --urls     explicit URLs, passed straight through
 *   --product  every how-to under one product folder, minus frozen version
 *              snapshot folders, filtered for testability
 *   --files    explicit how-to files, filtered for testability
 *   (none)     every how-to, filtered for testability
 *
 * Returns the URL list, plus the flag that says whether a page that only turns
 * out to be a non-first series page at render time aborts the whole batch.
 */
function toArray(value) {
  return Array.isArray(value) ? value : [value];
}

export async function resolveUrlsToTest(args, config, { repoRoot } = {}) {
  if (args.urls && args.product) {
    throw new Error("Pass either --urls or --product, not both.");
  }

  if (args.urls) {
    return {
      urlsToTest: toArray(args.urls),
      haltOnSeriesError: true,
    };
  }

  if (args.product) {
    const { files } = collectHowToFiles(args.product, { repoRoot });
    return {
      urlsToTest: await testeableUrlsFromFiles(config, files),
      // Scanning a whole product routinely hits non-first series pages;
      // log and skip them instead of aborting the rest of the batch.
      haltOnSeriesError: false,
    };
  }

  const howToFiles = args.files
    ? toArray(args.files)
    : await glob("../../app/_how-tos/**/*");

  return {
    urlsToTest: await testeableUrlsFromFiles(config, howToFiles, {
      explicit: !!args.files,
    }),
    haltOnSeriesError: true,
  };
}
