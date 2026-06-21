import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req: Request) => {
  // Health check — GET requests return 200 (useful for Dashboard testing)
  if (req.method === "GET") {
    return new Response(JSON.stringify({ status: "ok", provider: "anthropic" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 1. Verify auth
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: { message: "Missing auth token" } }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: { message: "Unauthorized — valid user JWT required" } }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 2. Parse request body
  let body;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: { message: "Invalid JSON body" } }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { model, system, messages, max_tokens, stream } = body;

  if (!model || !messages) {
    return new Response(JSON.stringify({ error: { message: "Missing required fields: model, messages" } }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 3. Proxy to Anthropic
  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: model,
        max_tokens: max_tokens || 1024,
        system: system || "",
        messages: messages,
        stream: stream || false,
      }),
    });

    return new Response(response.body, {
      status: response.status,
      headers: {
        "Content-Type": response.headers.get("Content-Type") || "application/json",
      },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: { message: `Proxy error: ${err.message}` } }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }
});
