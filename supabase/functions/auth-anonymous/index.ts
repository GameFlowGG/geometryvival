import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, handleCors } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { username } = await req.json();

    if (!username || typeof username !== "string" || username.trim().length === 0) {
      return Response.json({ error: "username required" }, { status: 400, headers: corsHeaders });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Create anonymous auth user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: `anon_${crypto.randomUUID()}@geometryvival.local`,
      password: crypto.randomUUID(),
      email_confirm: true,
    });

    if (authError || !authData.user) {
      return Response.json({ error: authError?.message }, { status: 500, headers: corsHeaders });
    }

    // Create account row
    const { error: accountError } = await supabase.from("accounts").insert({
      user_id: authData.user.id,
      username: username.trim(),
    });

    if (accountError) {
      return Response.json({ error: accountError.message }, { status: 500, headers: corsHeaders });
    }

    // Sign in to get a JWT the client can use
    const { data: signIn, error: signInError } = await supabase.auth.admin.generateLink({
      type: "magiclink",
      email: authData.user.email!,
    });

    // Use signInWithPassword approach — create with known password
    const password = crypto.randomUUID();
    await supabase.auth.admin.updateUser(authData.user.id, { password });

    const anonClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!
    );

    const { data: session, error: sessionError } = await anonClient.auth.signInWithPassword({
      email: authData.user.email!,
      password,
    });

    if (sessionError || !session.session) {
      return Response.json({ error: sessionError?.message }, { status: 500, headers: corsHeaders });
    }

    // Fetch account
    const { data: account } = await supabase
      .from("accounts")
      .select("*")
      .eq("user_id", authData.user.id)
      .single();

    return Response.json({
      access_token: session.session.access_token,
      refresh_token: session.session.refresh_token,
      account,
    }, { headers: corsHeaders });

  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500, headers: corsHeaders });
  }
});
