import fs from "fs";
import os from "os";
import path from "path";
import { spawnSync } from "child_process";

export function runTerraform(args, options = {}) {
  const bin = process.env.MESH_VALIDATOR_TERRAFORM_BIN || "terraform";
  const result = spawnSync(bin, args, { encoding: "utf-8", ...options });
  if (result.error) {
    throw new Error(
      `Failed to run "${bin}" (${result.error.message}). ` +
        "The validator needs the terraform binary on PATH, or a stub under " +
        "MESH_VALIDATOR_TERRAFORM_BIN.",
    );
  }
  return {
    status: result.status,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
}

// Grammar rule: write the block to a temp .tf file and run `terraform fmt`
// (write mode). The rewritten file is discarded, so style differences never
// matter; a non-zero exit means the block does not parse as HCL.
export function checkHclGrammar(blockText, run = runTerraform) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-hcl-"));
  try {
    fs.writeFileSync(path.join(dir, "block.tf"), blockText);
    const { status, stderr } = run(["fmt"], { cwd: dir });
    if (status !== 0) {
      const detail = stderr
        .split("\n")
        .map((line) => line.trim())
        .filter((line) => line.length > 0)
        .join(" ");
      return { message: `terraform fmt rejected the block: ${detail}` };
    }
    return null;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
