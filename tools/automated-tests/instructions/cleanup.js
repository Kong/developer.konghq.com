export async function processCleanup(cleanup) {
  let commands = [];
  for (const block of cleanup) {
    if (typeof block === "object") {
      console.warn("Unsupported: Cleanup of type object");
    } else {
      commands.push(block);
    }
  }
  return { commands };
}
