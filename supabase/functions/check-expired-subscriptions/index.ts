import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Buscar usuários com acesso anual expirado
  const now = new Date().toISOString();
  const { data: expired, error } = await supabase
    .from("usuarios")
    .select("id, email")
    .eq("tipo_acesso", "anual")
    .lt("acesso_anual_fim", now);

  if (error) {
    console.error("[EXPIRED] Erro ao buscar expirados:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  if (!expired || expired.length === 0) {
    console.log("[EXPIRED] Nenhum acesso expirado encontrado");
    return new Response(JSON.stringify({ updated: 0 }), { status: 200 });
  }

  const ids = expired.map((u: { id: string }) => u.id);

  // Atualizar status para bloqueado
  const { error: updateError } = await supabase
    .from("usuarios")
    .update({ tipo_acesso: "bloqueado" })
    .in("id", ids);

  if (updateError) {
    console.error("[EXPIRED] Erro ao atualizar usuários:", updateError);
    return new Response(JSON.stringify({ error: updateError.message }), { status: 500 });
  }

  // Atualizar status das assinaturas para expired
  await supabase
    .from("subscriptions")
    .update({ status: "expired" })
    .in("user_id", ids)
    .eq("status", "active");

  // Disparar e-mail de expiração para cada usuário (fire-and-forget)
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  for (const user of expired) {
    fetch(`${supabaseUrl}/functions/v1/send-email`, {
      method: "POST",
      headers: {
        "Content-Type":  "application/json",
        "Authorization": `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({
        user_id:    user.id,
        email_type: "subscription_expired",
      }),
    }).catch(err => console.error("[EXPIRED] Falha ao disparar e-mail:", user.id, err));
  }

  console.log(`[EXPIRED] ${ids.length} usuário(s) bloqueado(s):`, ids);
  return new Response(JSON.stringify({ updated: ids.length }), { status: 200 });
});
