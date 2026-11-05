import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-nexora-webhook-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function base64Url(input: string | Uint8Array): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function pemToBytes(pem: string): Uint8Array {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "").replace(/\s/g, "");
  const binary = atob(body);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function firebaseAccessToken(serviceAccount: Record<string, string>) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = header + "." + claims;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = unsigned + "." + base64Url(new Uint8Array(signature));
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const result = await response.json();
  if (!response.ok || !result.access_token) {
    throw new Error("Google OAuth token exchange failed");
  }
  return result.access_token as string;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    return json({ error: "Supabase function environment is incomplete" }, 500);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let trustedWebhook = false;
  const webhookSecret = Deno.env.get("NEXORA_PUSH_WEBHOOK_SECRET");
  const suppliedSecret = request.headers.get("x-nexora-webhook-secret");
  if (webhookSecret && suppliedSecret &&
      suppliedSecret.length === webhookSecret.length &&
      suppliedSecret === webhookSecret) {
    trustedWebhook = true;
  }

  let callerId: string | null = null;
  if (!trustedWebhook) {
    const authorization = request.headers.get("authorization") ?? "";
    const bearer = authorization.replace(/^Bearer\s+/i, "");
    if (!bearer) return json({ error: "Unauthorized" }, 401);
    const authClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await authClient.auth.getUser(bearer);
    if (error || !data.user) return json({ error: "Unauthorized" }, 401);
    callerId = data.user.id;
  }

  let body: { notification_id?: string };
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  const notificationId = body.notification_id;
  if (!notificationId || !/^[0-9a-f-]{36}$/i.test(notificationId)) {
    return json({ error: "notification_id is required" }, 400);
  }

  const { data: notification, error: notificationError } = await admin
    .from("notifications")
    .select("id,recipient_id,actor_id,notification_type,entity_id,payload")
    .eq("id", notificationId)
    .maybeSingle();
  if (notificationError || !notification) return json({ error: "Notification not found" }, 404);
  if (!trustedWebhook && notification.actor_id !== callerId) {
    return json({ error: "Not allowed to send this notification" }, 403);
  }

  const recipientId = notification.recipient_id as string;
  const category = notification.notification_type as string;
  const [{ data: userPreferences }, { data: categoryPreference }, { data: devices }] =
    await Promise.all([
      admin.from("user_preferences").select("push_notifications_enabled")
        .eq("user_id", recipientId).maybeSingle(),
      admin.from("notification_preferences").select("push")
        .eq("user_id", recipientId).eq("category", category).maybeSingle(),
      admin.from("user_devices").select("id,push_token")
        .eq("user_id", recipientId).eq("platform", "android"),
    ]);

  if (userPreferences?.push_notifications_enabled === false ||
      categoryPreference?.push === false) {
    return json({ sent: 0, skipped: "push_disabled" });
  }
  if (!devices?.length) return json({ sent: 0, skipped: "no_registered_devices" });

  const credentialsRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!credentialsRaw) {
    return json({ error: "FIREBASE_SERVICE_ACCOUNT_JSON secret is not configured" }, 503);
  }

  let serviceAccount: Record<string, string>;
  try {
    serviceAccount = JSON.parse(credentialsRaw);
  } catch {
    return json({ error: "Firebase service account secret is invalid JSON" }, 500);
  }
  if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
    return json({ error: "Firebase service account is missing required fields" }, 500);
  }

  const payload = (notification.payload ?? {}) as Record<string, unknown>;
  const title = typeof payload.title === "string" ? payload.title : "NEXORA";
  const messageBody = typeof payload.body === "string"
    ? payload.body
    : category === "message" ? "لديك رسالة جديدة" : "لديك إشعار جديد";
  const accessToken = await firebaseAccessToken(serviceAccount);

  let sent = 0;
  let failed = 0;
  for (const device of devices) {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: device.push_token,
            notification: { title, body: messageBody },
            data: {
              notification_id: notification.id,
              notification_type: category,
              entity_id: notification.entity_id ?? "",
            },
            android: { priority: "HIGH" },
          },
        }),
      },
    );
    if (response.ok) {
      sent++;
    } else {
      failed++;
      const responseText = await response.text();
      if (response.status === 404 || responseText.includes("UNREGISTERED")) {
        await admin.from("user_devices").delete().eq("id", device.id);
      }
    }
  }

  return json({ sent, failed, total: devices.length });
});
