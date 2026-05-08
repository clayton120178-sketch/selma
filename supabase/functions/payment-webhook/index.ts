import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DAYS = 365;

// Verificação HMAC — garante que o POST veio do Mercado Pago
async function verifyMPSignature(req: Request, _rawBody: string): Promise<boolean> {
  const secret = Deno.env.get("MP_WEBHOOK_SECRET");
  if (!secret) {
    console.error("[SECURITY] MP_WEBHOOK_SECRET não configurado — rejeitando webhook");
    return false;
  }

  const xSignature = req.headers.get("x-signature");
  const xRequestId = req.headers.get("x-request-id");
  const dataId     = new URL(req.url).searchParams.get("data.id");

  if (!xSignature || !xRequestId) {
    console.error("[SECURITY] Headers de assinatura ausentes");
    return false;
  }

  const parts: Record<string, string> = {};
  for (const part of xSignature.split(",")) {
    const [k, v] = part.split("=");
    if (k && v) parts[k.trim()] = v.trim();
  }

  if (!parts.ts || !parts.v1) {
    console.error("[SECURITY] Formato de x-signature inválido");
    return false;
  }

  const signedTemplate = `id:${dataId};request-id:${xRequestId};ts:${parts.ts};`;
  const encoder        = new TextEncoder();

  const cryptoKey = await crypto.subtle.importKey(
    "raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );

  const signatureBuffer = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(signedTemplate));
  const computed = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");

  // Comparação em tempo constante (evita timing attacks)
  if (computed.length !== parts.v1.length) return false;
  let result = 0;
  for (let i = 0; i < computed.length; i++) {
    result |= computed.charCodeAt(i) ^ parts.v1.charCodeAt(i);
  }

  const valid = result === 0;
  if (!valid) console.error("[SECURITY] Assinatura MP inválida — webhook rejeitado");
  return valid;
}

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

  let rawBody: string;
  try { rawBody = await req.text(); }
  catch { return new Response("Bad Request", { status: 400 }); }

  const signatureValid = await verifyMPSignature(req, rawBody);
  if (!signatureValid) {
    console.error("[SECURITY] Webhook rejeitado — IP:", req.headers.get("x-forwarded-for") ?? "unknown");
    return new Response("ok", { status: 200 }); // sempre 200 para não reenviar
  }

  let body: Record<string, unknown>;
  try { body = JSON.parse(rawBody); }
  catch { return new Response("ok", { status: 200 }); }

  // Processar apenas eventos de pagamento
  if (body.type !== "payment") return new Response("ok", { status: 200 });

  const paymentId = (body.data as Record<string, unknown>)?.id;
  if (!paymentId) return new Response("ok", { status: 200 });

  // Buscar dados reais no MP — NUNCA confiar no body do webhook
  const MP_TOKEN = Deno.env.get("MP_ACCESS_TOKEN")!;
  let payment: Record<string, unknown>;
  try {
    const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { "Authorization": `Bearer ${MP_TOKEN}` },
    });
    if (!mpRes.ok) {
      console.error("[MP] Erro ao buscar pagamento:", mpRes.status);
      return new Response("error", { status: 500 });
    }
    payment = await mpRes.json() as Record<string, unknown>;
  } catch (err) {
    console.error("[MP] Falha na requisição:", err);
    return new Response("error", { status: 500 });
  }

  // Processar apenas pagamentos aprovados
  if (payment.status !== "approved") return new Response("ok", { status: 200 });

  // Validar metadata com whitelist
  const meta    = payment.metadata as Record<string, unknown> | undefined;
  const user_id = typeof meta?.user_id === "string" ? meta.user_id : null;
  const plan    = typeof meta?.plan    === "string" ? meta.plan    : null;

  if (!user_id || plan !== "anual") {
    console.error("[WEBHOOK] Metadata inválida:", meta);
    return new Response("ok", { status: 200 });
  }

  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!UUID_RE.test(user_id)) {
    console.error("[SECURITY] user_id inválido:", user_id);
    return new Response("ok", { status: 200 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Idempotência: verificar se já foi processado
  const { data: existing } = await supabase
    .from("subscriptions")
    .select("id")
    .eq("payment_ref", String(paymentId))
    .maybeSingle();

  if (existing) {
    console.log("[WEBHOOK] Já processado:", paymentId);
    return new Response("ok", { status: 200 });
  }

  // Verificar que o usuário existe
  const { data: userExists } = await supabase
    .from("usuarios")
    .select("id")
    .eq("id", user_id)
    .maybeSingle();

  if (!userExists) {
    console.error("[WEBHOOK] user_id não encontrado:", user_id);
    return new Response("ok", { status: 200 });
  }

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + DAYS);

  const paymentMethod =
    payment.payment_type_id === "bank_transfer" ? "pix" :
    payment.payment_type_id === "debit_card"    ? "cartao_debito" : "cartao";

  // Ativar acesso anual no usuário
  const { error: updateError } = await supabase.from("usuarios").update({
    tipo_acesso:         "anual",
    acesso_anual_inicio: new Date().toISOString(),
    acesso_anual_fim:    expiresAt.toISOString(),
  }).eq("id", user_id);

  if (updateError) {
    console.error("[WEBHOOK] Erro ao ativar acesso:", updateError);
    return new Response("error", { status: 500 });
  }

  // Registrar no log de assinaturas
  const { error } = await supabase.from("subscriptions").insert({
    user_id,
    plan:           "anual",
    cycle:          "anual",
    expires_at:     expiresAt.toISOString(),
    status:         "active",
    payment_method: paymentMethod,
    payment_ref:    String(paymentId),
    amount: typeof payment.transaction_amount === "number" ? payment.transaction_amount : null,
  });

  if (error) {
    if (error.code === "23505") {
      console.log("[WEBHOOK] Race condition — já registrada:", paymentId);
      return new Response("ok", { status: 200 });
    }
    console.error("[WEBHOOK] Erro ao registrar assinatura:", error);
  }

  console.log("[WEBHOOK] Acesso anual ativado — user:", user_id);

  // Disparar e-mail de confirmação (fire-and-forget)
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  fetch(`${supabaseUrl}/functions/v1/send-email`, {
    method: "POST",
    headers: {
      "Content-Type":  "application/json",
      "Authorization": `Bearer ${serviceKey}`,
    },
    body: JSON.stringify({
      user_id,
      email_type: "subscription_confirmed",
      metadata: { expires_at: expiresAt.toISOString() },
    }),
  }).catch(err => console.error("[WEBHOOK] Falha ao disparar e-mail:", err));

  return new Response("ok", { status: 200 });
});
