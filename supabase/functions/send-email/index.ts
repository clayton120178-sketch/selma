import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type EmailType = "subscription_confirmed" | "subscription_expired";

interface EmailPayload {
  user_id:    string;
  email_type: EmailType;
  metadata?:  Record<string, unknown>;
}

function buildEmail(type: EmailType, toEmail: string, meta: Record<string, unknown> = {}) {
  if (type === "subscription_confirmed") {
    const expiresAt = meta.expires_at
      ? new Date(meta.expires_at as string).toLocaleDateString("pt-BR")
      : "em 1 ano";
    return {
      subject: "Seu acesso anual ao Pulso Anota está ativo! 🎉",
      html: `
        <div style="font-family:sans-serif;max-width:560px;margin:0 auto">
          <h2 style="color:#0D9488">Pagamento confirmado!</h2>
          <p>Olá,</p>
          <p>Seu acesso anual ao <strong>Pulso Anota</strong> foi ativado com sucesso.</p>
          <p>Você tem acesso ilimitado até <strong>${expiresAt}</strong>.</p>
          <p style="margin-top:24px">
            <a href="https://anota.pulsoenfermagem.com.br"
               style="background:#0D9488;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:bold">
              Acessar o app
            </a>
          </p>
          <p style="margin-top:32px;font-size:13px;color:#666">
            Dúvidas? Responda este e-mail.<br>
            Equipe Pulso Enfermagem
          </p>
        </div>
      `,
    };
  }

  // subscription_expired
  return {
    subject: "Seu acesso ao Pulso Anota expirou",
    html: `
      <div style="font-family:sans-serif;max-width:560px;margin:0 auto">
        <h2 style="color:#0D9488">Acesso expirado</h2>
        <p>Olá,</p>
        <p>Seu acesso anual ao <strong>Pulso Anota</strong> expirou.</p>
        <p>Renove agora para continuar gerando suas anotações de enfermagem com segurança.</p>
        <p style="margin-top:24px">
          <a href="https://anota.pulsoenfermagem.com.br"
             style="background:#0D9488;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:bold">
            Renovar acesso — R$&nbsp;79,90/ano
          </a>
        </p>
        <p style="margin-top:32px;font-size:13px;color:#666">
          Equipe Pulso Enfermagem
        </p>
      </div>
    `,
  };
}

serve(async (req) => {
  let payload: EmailPayload;
  try {
    payload = await req.json() as EmailPayload;
  } catch {
    return new Response("Bad Request", { status: 400 });
  }

  const { user_id, email_type, metadata = {} } = payload;

  if (!user_id || !["subscription_confirmed", "subscription_expired"].includes(email_type)) {
    return new Response("Invalid payload", { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Buscar e-mail do usuário
  const { data: userData, error: userError } = await supabase
    .from("usuarios")
    .select("email")
    .eq("id", user_id)
    .maybeSingle();

  if (userError || !userData?.email) {
    console.error("[EMAIL] Usuário não encontrado:", user_id);
    return new Response("User not found", { status: 404 });
  }

  const toEmail  = userData.email as string;
  const { subject, html } = buildEmail(email_type, toEmail, metadata);

  const RESEND_KEY = Deno.env.get("RESEND_API_KEY");
  let resendId: string | null = null;
  let status: "sent" | "failed" = "sent";

  if (!RESEND_KEY) {
    // Modo stub — loga sem enviar
    console.log(`[EMAIL:STUB] Para: ${toEmail} | Tipo: ${email_type} | Assunto: ${subject}`);
  } else {
    try {
      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Content-Type":  "application/json",
          "Authorization": `Bearer ${RESEND_KEY}`,
        },
        body: JSON.stringify({
          from:    "Pulso Enfermagem <noreply@pulsoenfermagem.com.br>",
          to:      [toEmail],
          subject,
          html,
        }),
      });

      const resData = await res.json() as Record<string, unknown>;
      if (res.ok) {
        resendId = resData.id as string;
        console.log("[EMAIL] Enviado:", resendId);
      } else {
        console.error("[EMAIL] Erro Resend:", resData);
        status = "failed";
      }
    } catch (err) {
      console.error("[EMAIL] Falha na requisição Resend:", err);
      status = "failed";
    }
  }

  // Registrar no log
  await supabase.from("email_logs").insert({
    user_id,
    email_type,
    status,
    resend_id: resendId,
    metadata,
  });

  return new Response(JSON.stringify({ status }), {
    headers: { "Content-Type": "application/json" },
  });
});
