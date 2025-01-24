export async function processPrereqs(prereqs) {
  let commands = [];
  for (const block of prereqs.blocks) {
    if (typeof block === "object") {
      // TODO: process prereqs of type object
      console.warn("Unsupported: Prereq of type object");
    } else {
      commands.push(block);
    }
  }
  return { commands };
}
