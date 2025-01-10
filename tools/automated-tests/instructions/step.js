export async function processSteps(steps) {
  let commands = [];
  for (const step of steps) {
    if (typeof step === "object") {
      // TODO: process step of type object
      console.warn("Unsupported: Step of type object");
    } else {
      commands.push(step);
    }
  }
  return { commands };
}
