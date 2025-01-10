export async function processCleanup(cleanup) {
  let commands = [];
  for (const command of cleanup) {
    if (typeof command === "object") {
      // TODO: process cleanup of type object
      console.warn("Unsupported: Cleanup of type object");
    } else {
      commands.push(command);
    }
  }
  return { commands };
}
