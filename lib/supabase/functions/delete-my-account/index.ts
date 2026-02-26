import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // user client (to identify caller)
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData } = await userClient.auth.getUser();
    const user = userData?.user;
    if (!user) {
      return new Response(
        JSON.stringify({ ok: false, message: "Not authenticated" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // admin client (service role)
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const userId = user.id;

    // 1) delete prescriptions storage objects under "userId/"
    // list in pages (simple loop)
    let offset = 0;
    const limit = 100;
    while (true) {
      const { data: list, error } = await adminClient.storage
        .from("prescriptions")
        .list(userId, { limit, offset });

      if (error) break;
      if (!list || list.length === 0) break;

      const paths = list
        .filter((o) => o.name)
        .map((o) => `${userId}/${o.name}`);

      if (paths.isNotEmpty) {
        await adminClient.storage.from("prescriptions").remove(paths);
      }

      if (list.length < limit) break;
      offset += limit;
    }

    // 2) delete the auth user (DB cascades handle the rest)
    const { error: delErr } = await adminClient.auth.admin.deleteUser(userId);
    if (delErr) {
      return new Response(
        JSON.stringify({ ok: false, message: "Failed to delete user", details: delErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ ok: true, message: "Account deleted" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, message: "Server error", error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});