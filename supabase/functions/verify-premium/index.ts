import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const APPLE_BUNDLE_ID =
  Deno.env.get("APPLE_BUNDLE_ID") ?? "com.ggozali.pawmento.devapp";
const ALLOWED_PRODUCT_IDS = new Set(
  (Deno.env.get("ALLOWED_PRODUCT_IDS") ??
    "com.ggozali.pawmento.devapp.pro.monthly")
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean),
);

interface AppleTransactionPayload {
  transactionId?: string;
  originalTransactionId?: string;
  bundleId?: string;
  productId?: string;
  environment?: string;
  revocationDate?: number;
  expiresDate?: number;
}

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}


async function verifyAppleSignedTransaction(
  signedTransaction: string,
): Promise<AppleTransactionPayload> {
  const parts = signedTransaction.split(".");
  if (parts.length !== 3) {
    throw new Error("Invalid signed transaction format");
  }

  const header = jose.decodeProtectedHeader(signedTransaction);
  const x5c = header.x5c;
  if (!x5c?.length) {
    throw new Error("Signed transaction missing certificate chain");
  }

  const leafPem =
    `-----BEGIN CERTIFICATE-----\n${x5c[0]}\n-----END CERTIFICATE-----`;
  const key = await jose.importX509(leafPem, "ES256");
  const { payload } = await jose.compactVerify(signedTransaction, key);

  return JSON.parse(new TextDecoder().decode(payload)) as AppleTransactionPayload;
}

function validateTransactionPayload(
  payload: AppleTransactionPayload,
): { transactionId: string; planType: string } {
  const transactionId = payload.transactionId?.trim();
  if (!transactionId) {
    throw new Error("Signed transaction missing transactionId");
  }

  if (payload.bundleId !== APPLE_BUNDLE_ID) {
    throw new Error("Signed transaction bundleId mismatch");
  }

  const productId = payload.productId?.trim();
  if (!productId || !ALLOWED_PRODUCT_IDS.has(productId)) {
    throw new Error("Signed transaction productId is not allowed");
  }

  if (payload.revocationDate) {
    throw new Error("Signed transaction has been revoked");
  }

  if (payload.expiresDate && payload.expiresDate < Date.now()) {
    throw new Error("Signed transaction has expired");
  }

  return {
    transactionId,
    planType: "pro",
  };
}

async function verifyWithAppStoreServerAPI(
  transactionId: string,
): Promise<void> {
  const issuerId = Deno.env.get("APPLE_APP_STORE_ISSUER_ID");
  const keyId = Deno.env.get("APPLE_APP_STORE_KEY_ID");
  const privateKeyPem = Deno.env.get("APPLE_APP_STORE_PRIVATE_KEY");

  if (!issuerId || !keyId || !privateKeyPem) {
    return;
  }

  const normalizedKey = privateKeyPem.replace(/\\n/g, "\n");
  const apiKey = await jose.importPKCS8(normalizedKey, "ES256");
  const apiToken = await new jose.SignJWT({ bid: APPLE_BUNDLE_ID })
    .setProtectedHeader({ alg: "ES256", kid: keyId, typ: "JWT" })
    .setIssuer(issuerId)
    .setAudience("appstoreconnect-v1")
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(apiKey);

  const hosts = [
    "https://api.storekit.itunes.apple.com",
    "https://api.storekit-sandbox.itunes.apple.com",
  ];

  let lastStatus = 0;
  for (const host of hosts) {
    const response = await fetch(
      `${host}/inApps/v1/transactions/${transactionId}`,
      {
        headers: { Authorization: `Bearer ${apiToken}` },
      },
    );

    lastStatus = response.status;
    if (response.status === 404) {
      continue;
    }

    if (!response.ok) {
      throw new Error(`App Store Server API error (${response.status})`);
    }

    const data = await response.json() as { signedTransactionInfo?: string };
    if (!data.signedTransactionInfo) {
      throw new Error("App Store Server API returned no signed transaction");
    }

    const apiPayload = await verifyAppleSignedTransaction(
      data.signedTransactionInfo,
    );
    if (apiPayload.transactionId !== transactionId) {
      throw new Error("App Store Server API transaction mismatch");
    }

    validateTransactionPayload(apiPayload);
    return;
  }

  throw new Error(
    `Transaction not found in App Store Server API (${lastStatus})`,
  );
}

Deno.serve(async (req: Request) => {
  if (req.method === "GET") {
    return jsonResponse({ status: "ok", service: "verify-premium" }, 200);
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: { message: "Method not allowed" } }, 405);
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

  let body: { signed_transaction?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: { message: "Invalid JSON body" } }, 400);
  }

  const signedTransaction = body.signed_transaction?.trim();
  if (!signedTransaction) {
    return jsonResponse(
      { error: { message: "signed_transaction is required" } },
      400,
    );
  }

  let transactionId: string;
  let planType: string;
  try {
    const payload = await verifyAppleSignedTransaction(signedTransaction);
    ({ transactionId, planType } = validateTransactionPayload(payload));
    await verifyWithAppStoreServerAPI(transactionId);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Verification failed";
    return jsonResponse({ error: { message } }, 400);
  }

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { error: rpcError } = await adminClient.rpc(
    "activate_premium_subscription_verified",
    {
      p_user_id: user.id,
      p_plan_type: planType,
      p_transaction_id: transactionId,
    },
  );

  if (rpcError) {
    const status = rpcError.message.includes("another account") ? 409 : 500;
    return jsonResponse({ error: { message: rpcError.message } }, status);
  }

  return jsonResponse({ ok: true, transaction_id: transactionId }, 200);
});
