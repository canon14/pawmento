// Follow the README for deployment: see ai-proxy/README.md
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

Deno.serve(async (req: Request) => {
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
    return new Response(JSON.stringify({ error: { message: "Unauthorized" } }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 2. Parse request body
  const body = await req.json();
  const { provider, model, system, messages, max_tokens, stream } = body;

  if (!provider || !model || !messages) {
    return new Response(JSON.stringify({ error: { message: "Missing required fields: provider, model, messages" } }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // 3. Optional: Enforce quota (uncomment to enable)
  // const { data: profile } = await supabase.from("user_profiles").select("questions_used, subscription_tier").eq("id", user.id).single();
  // if (profile?.subscription_tier === "free" && profile?.questions_used >= 5) {
  //   return new Response(JSON.stringify({ error: { message: "Free tier quota exceeded" } }), { status: 429, headers: { "Content-Type": "application/json" } });
  // }

  // 4. Proxy to the correct provider
  if (provider === "anthropic") {
    return proxyAnthropic({ model, system, messages, max_tokens: max_tokens || 1024, stream: stream || false });
  } else if (provider === "openai") {
    return proxyOpenAI({ model, system, messages, max_tokens: max_tokens || 1024, stream: stream || false });
  } else {
    return new Response(JSON.stringify({ error: { message: `Unknown provider: ${provider}` } }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});

async function proxyAnthropic(params: {
  model: string;
  system: string;
  messages: Array<{ role: string; content: string }>;
  max_tokens: number;
  stream: boolean;
}) {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: params.model,
      max_tokens: params.max_tokens,
      system: params.system,
      messages: params.messages,
      stream: params.stream,
    }),
  });

  // Pass through the response (including SSE streaming) directly
  return new Response(response.body, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
    },
  });
}

async function proxyOpenAI(params: {
  model: string;
  system: string;
  messages: Array<{ role: string; content: string }>;
  max_tokens: number;
  stream: boolean;
}) {
  const openaiMessages = [
    { role: "system", content: params.system },
    ...params.messages,
  ];

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: params.model,
      max_tokens: params.max_tokens,
      messages: openaiMessages,
      stream: params.stream,
    }),
  });

  return new Response(response.body, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
    },
  });
}
