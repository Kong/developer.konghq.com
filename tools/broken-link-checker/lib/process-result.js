export default function processResult(result) {
  const { brokenLinks, otherErrors } = result;

  if (otherErrors.length) {
    console.warn(
      `${otherErrors.length} links have issues but returned a status code other than 404!`
    );
    console.log(JSON.stringify(otherErrors, null, 2));
  }

  if (brokenLinks.length) {
    console.error(`${brokenLinks.length} Broken links found!`);
    console.log(JSON.stringify(brokenLinks, null, 2));
    process.exit(1);
  }
  console.log("No broken links detected.");
}
