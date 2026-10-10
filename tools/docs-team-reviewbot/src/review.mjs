// Manual tool loop against the Messages API (official SDK, beta namespace for
// server-side refusal fallbacks). Read-only tools only.
import { LIMITS, MODEL, EFFORT } from "./config.mjs";
import { TOOL_DEFS, runTool } from "./tools.mjs";

export function extractJson(text) {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch {
    return null;
  }
}

const textOf = (content) => content.filter((b) => b.type === "text").map((b) => b.text).join("\n");

export async function reviewPR({ client, system, userContent, repoRoot, log = () => {} }) {
  const messages = [{ role: "user", content: userContent }];
  const usage = { input: 0, output: 0, cache_read: 0, cache_write: 0 };
  let toolCalls = 0;
  let repaired = false;
  let fallbackRan = false;

  for (let turn = 1; turn <= LIMITS.maxToolTurns; turn++) {
    const params = {
      model: MODEL,
      max_tokens: LIMITS.maxOutputTokens,
      output_config: { effort: EFFORT },
      system: [{ type: "text", text: system, cache_control: { type: "ephemeral" } }],
      tools: TOOL_DEFS,
      messages,
    };
    if (process.env.REVIEWBOT_FALLBACKS !== "off") {
      params.betas = ["server-side-fallback-2026-07-01"];
      params.fallbacks = "default";
    }
    const res = await client.beta.messages.create(params);
    usage.input += res.usage?.input_tokens ?? 0;
    usage.output += res.usage?.output_tokens ?? 0;
    usage.cache_read += res.usage?.cache_read_input_tokens ?? 0;
    usage.cache_write += res.usage?.cache_creation_input_tokens ?? 0;
    if ((res.usage?.iterations ?? []).some((i) => i.type === "fallback_message")) fallbackRan = true;

    if (res.stop_reason === "refusal") return { status: "refused", usage, toolCalls, turns: turn, stop_details: res.stop_details ?? null };
    if (res.stop_reason === "max_tokens") return { status: "max_tokens", usage, toolCalls, turns: turn };

    // Always echo the full assistant content back (thinking blocks included).
    messages.push({ role: "assistant", content: res.content });

    if (res.stop_reason === "tool_use") {
      const results = [];
      for (const block of res.content) {
        if (block.type !== "tool_use") continue;
        toolCalls++;
        try {
          const out = await runTool(repoRoot, block.name, block.input ?? {});
          results.push({ type: "tool_result", tool_use_id: block.id, content: out });
        } catch (e) {
          results.push({ type: "tool_result", tool_use_id: block.id, content: String(e.message || e), is_error: true });
        }
      }
      messages.push({ role: "user", content: results });
      continue;
    }

    const parsed = extractJson(textOf(res.content));
    if (parsed) return { status: "ok", result: parsed, usage, toolCalls, turns: turn, model: res.model, fallbackRan };
    if (repaired) return { status: "bad_json", usage, toolCalls, turns: turn };
    repaired = true;
    log("final message was not valid JSON; asking once more");
    messages.push({ role: "user", content: "Return only the JSON object from the output contract, with no other text." });
  }
  return { status: "too_many_turns", usage, toolCalls, turns: LIMITS.maxToolTurns };
}
