import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { buildSystemPrompt } from "./prompts.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Keep in sync with PawMento/Core/AI/AIConfig.swift
const DEFAULT_MODEL = Deno.env.get("ANTHROPIC_MODEL") ??
  "claude-haiku-4-5-20251001";
const ALLOWED_MODELS = new Set(
  (Deno.env.get("ALLOWED_ANTHROPIC_MODELS") ?? DEFAULT_MODEL)
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean),
);
const DEFAULT_MAX_TOKENS = 1024;
const MAX_MAX_TOKENS = 4096;

function resolveModel(_clientModel: unknown): string {
  // Pin to server default — never forward client-chosen models to Anthropic.
  if (ALLOWED_MODELS.has(DEFAULT_MODEL)) {
    return DEFAULT_MODEL;
  }
  return [...ALLOWED_MODELS][0];
}

function resolveMaxTokens(clientMax: unknown): number {
  const requested = typeof clientMax === "number" && Number.isFinite(clientMax)
    ? Math.floor(clientMax)
    : DEFAULT_MAX_TOKENS;
  return Math.min(Math.max(requested, 1), MAX_MAX_TOKENS);
}

function jsonResponse(
  body: Record<string, unknown>,
  status: number,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...extraHeaders,
    },
  });
}

async function getQuotaRemaining(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
): Promise<number> {
  const { data, error } = await adminClient.rpc(
    "coach_question_quota_remaining",
    { p_user_id: userId },
  );

  if (error) {
    throw new Error(`Quota lookup failed: ${error.message}`);
  }

  return data as number;
}

async function consumeQuota(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
): Promise<number> {
  const { data, error } = await adminClient.rpc(
    "consume_coach_question_usage",
    { p_user_id: userId },
  );

  if (error) {
    throw new Error(`Quota consume failed: ${error.message}`);
  }

  return data as number;
}

function sseChunkHasContent(chunkText: string): boolean {
  for (const line of chunkText.split("\n")) {
    if (!line.startsWith("data: ")) continue;
    const payload = line.slice(6).trim();
    if (!payload || payload === "[DONE]") continue;

    try {
      const event = JSON.parse(payload);
      if (event.type === "content_block_delta") {
        const text = event.delta?.text;
        if (typeof text === "string" && text.length > 0) {
          return true;
        }
      }
    } catch {
      // Ignore malformed SSE lines.
    }
  }

  return false;
}

function wrapStreamingResponse(
  upstream: Response,
  onSuccess: () => Promise<number | null>,
): Response {
  const reader = upstream.body!.getReader();
  const decoder = new TextDecoder();
  let sawContent = false;
  let consumed = false;

  const stream = new ReadableStream({
    async pull(controller) {
      try {
        const { done, value } = await reader.read();

        if (done) {
          if (sawContent && !consumed) {
            consumed = true;
            const remaining = await onSuccess();
            if (remaining !== null && remaining >= 0) {
              controller.enqueue(
                new TextEncoder().encode(
                  `event: quota\ndata: ${JSON.stringify({ remaining })}\n\n`,
                ),
              );
            }
          }
          controller.close();
          return;
        }

        const chunkText = decoder.decode(value, { stream: true });
        if (!sawContent && sseChunkHasContent(chunkText)) {
          sawContent = true;
        }

        controller.enqueue(value);
      } catch (err) {
        controller.error(err);
      }
    },
  });

  const headers = new Headers(upstream.headers);
  headers.set("Content-Type", upstream.headers.get("Content-Type") ||
    "text/event-stream");

  return new Response(stream, {
    status: upstream.status,
    headers,
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "GET") {
    return jsonResponse({ status: "ok", provider: "anthropic" }, 200);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: { message: "Missing auth token" } }, 401);
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse(
      { error: { message: "Unauthorized — valid user JWT required" } },
      401,
    );
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: { message: "Invalid JSON body" } }, 400);
  }

  const { system, messages, max_tokens, stream, exempt_quota, purpose } = body;

  const isQuotaExempt =
    exempt_quota === true && purpose === "welcome_primer";

  if (!messages) {
    return jsonResponse(
      { error: { message: "Missing required field: messages" } },
      400,
    );
  }

  const model = resolveModel(body.model);
  const resolvedMaxTokens = resolveMaxTokens(max_tokens);
  const resolvedSystem = buildSystemPrompt(system, Boolean(stream));

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let quotaRemaining: number;
  try {
    quotaRemaining = await getQuotaRemaining(adminClient, user.id);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Quota check failed";
    return jsonResponse({ error: { message } }, 500);
  }

  if (!isQuotaExempt && quotaRemaining === 0) {
    return jsonResponse(
      {
        error: {
          code: "coach_quota_exhausted",
          message: "Free coach question quota exhausted for this period",
        },
      },
      429,
      { "X-Coach-Questions-Remaining": "0" },
    );
  }

  const isPremium = quotaRemaining < 0;

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model,
        max_tokens: resolvedMaxTokens,
        system: resolvedSystem,
        messages,
        stream: stream || false,
      }),
    });

    if (!response.ok) {
      return new Response(response.body, {
        status: response.status,
        headers: {
          "Content-Type": response.headers.get("Content-Type") ||
            "application/json",
        },
      });
    }

    if (stream) {
      if (isPremium || isQuotaExempt) {
        return new Response(response.body, {
          status: response.status,
          headers: {
            "Content-Type": response.headers.get("Content-Type") ||
              "text/event-stream",
            "X-Coach-Questions-Remaining": isPremium
              ? "-1"
              : String(quotaRemaining),
          },
        });
      }

      return wrapStreamingResponse(response, async () => {
        return await consumeQuota(adminClient, user.id);
      });
    }

    if (!isPremium && !isQuotaExempt) {
      quotaRemaining = await consumeQuota(adminClient, user.id);
    }

    const headers: Record<string, string> = {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
      "X-Coach-Questions-Remaining": String(quotaRemaining),
    };

    return new Response(response.body, {
      status: response.status,
      headers,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return jsonResponse({ error: { message: `Proxy error: ${message}` } }, 502);
  }
});
