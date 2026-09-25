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

function compactDetail(stderr) {
  return stderr
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .slice(0, 3)
    .join(" ");
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
      return {
        message: `terraform fmt rejected the block: ${compactDetail(stderr)}`,
      };
    }
    return null;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

export const KONNECT_BETA_PROVIDER_VERSION = "0.22.0";

// The harness wrapped around every published block: the pinned provider, an
// empty provider block (validate never contacts Konnect and needs no token),
// and stub resources for the mesh references the published blocks carry.
const HARNESS = `terraform {
  required_providers {
    konnect-beta = {
      source  = "kong/konnect-beta"
      version = "${KONNECT_BETA_PROVIDER_VERSION}"
    }
  }
}

provider "konnect-beta" {}

resource "konnect_mesh" "my_mesh" {
  provider = konnect-beta
  cp_id    = konnect_mesh_control_plane.my_meshcontrolplane.id
  name     = "my_mesh"
  type     = "Mesh"
}

resource "konnect_mesh_control_plane" "my_meshcontrolplane" {
  provider = konnect-beta
  name     = "my_meshcontrolplane"
}

`;

// Provider-schema rule: assemble the harness plus the published block in a
// temp directory, then run `terraform init` and `terraform validate` there.
// The caller sets TF_PLUGIN_CACHE_DIR in `env` so the provider downloads once
// per run, and turns the finding into an advisory or gating finding.
export function checkProviderSchema(blockText, env = process.env) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "mesh-policy-tf-"));
  try {
    fs.writeFileSync(path.join(dir, "main.tf"), HARNESS + blockText);
    const init = runTerraform(["init", "-no-color", "-input=false"], {
      cwd: dir,
      env,
    });
    if (init.status !== 0) {
      return {
        message: `terraform init failed: ${compactDetail(init.stderr)}`,
      };
    }
    const validate = runTerraform(["validate", "-no-color"], { cwd: dir, env });
    if (validate.status !== 0) {
      return {
        message: `terraform validate failed: ${compactDetail(validate.stderr)}`,
      };
    }
    return null;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}
