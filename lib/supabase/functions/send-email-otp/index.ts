import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle preflight (browser will send OPTIONS)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !RESEND_API_KEY) {
      return new Response(
        JSON.stringify({ ok: false, message: "Missing server env vars" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Use caller JWT from Authorization header
    const authHeader = req.headers.get("Authorization") ?? "";

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    // Identify user
    const { data: userData, error: userErr } = await supabase.auth.getUser();
    const email = userData?.user?.email;

    if (userErr || !email) {
      return new Response(
        JSON.stringify({ ok: false, message: "Not authenticated" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Create OTP (your SQL function returns the plain 6-digit code)
    const { data: code, error: otpErr } = await supabase.rpc("create_email_otp");
    if (otpErr || !code) {
      return new Response(
        JSON.stringify({ ok: false, message: "Failed to create OTP", details: otpErr?.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Send using Resend
    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        // For testing (until you verify a domain). Resend may restrict recipients.
        from: "PharmC <onboarding@resend.dev>",
        to: [email],
        subject: "Your PharmC verification code",
        html: `
          <div style="font-family:Arial,sans-serif">
            <h2>PharmC Verification</h2>
            <p>Your verification code is:</p>
            <div style="font-size:32px;letter-spacing:6px;font-weight:700">${code}</div>
            <p style="color:#666">This code expires in 10 minutes.</p>
          </div>
        `,
      }),
    });

    if (!resendResp.ok) {
      const text = await resendResp.text();
      return new Response(
        JSON.stringify({ ok: false, message: "Email sending failed", details: text }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ ok: true, message: "OTP sent" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, message: "Server error", error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});