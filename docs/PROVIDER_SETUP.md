# NEXORA provider and key setup

## Supabase client

The Flutter client uses the active Supabase project URL and a public publishable/anon key. These values may be present in Android/Web clients when Row Level Security and grants are correctly configured. Never ship a Supabase `service_role` or secret key.

The manual release workflow accepts optional GitHub Actions secrets named `SUPABASE_URL` and `SUPABASE_ANON_KEY`. If they are absent, it uses the public client configuration in the workflow.

## Phone authentication (SMS)

The app uses phone OTP through Supabase Auth with `OtpChannel.sms`; WhatsApp delivery is not part of the current implementation. Email/password remains an alternative.

Dashboard setup required before real SMS delivery:
1. Open Supabase Dashboard → Authentication → Sign In / Providers → Phone.
2. Enable Phone provider.
3. Configure a supported SMS provider and its credentials/template according to the provider's Supabase integration.
4. Set suitable OTP expiry and rate limits for the intended launch region.
5. Test new signup, existing-user login, resend, wrong/expired OTP, and Egyptian/international number formats with real phones.

SMS delivery is not considered verified until a real code is received and successfully verified. Provider charges, country coverage, and sender registration are external dependencies.

## Push notifications

Firebase Cloud Messaging integration code, the Supabase `send-push-notification` Edge Function, and the database notification trigger are deployed. The following server-only secrets belong in Supabase Edge Functions → Secrets:
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `NEXORA_PUSH_WEBHOOK_SECRET`

The matching webhook secret is also stored in Supabase Vault. Never place either secret in Flutter, a web bundle, GitHub source, or chat messages. See [FCM setup](FCM_SETUP.md).

Push delivery is not fully verified until a signed-in Android device grants notification permission, registers its Firebase Installation ID, and receives a real notification.

## Voice and video calls

The database contains call-session and participant records, not a completed calling system. Production WebRTC still requires signaling lifecycle, TURN infrastructure, server-only TURN credentials, incoming-call delivery, permission handling, and real-device tests across different networks. Do not advertise voice/video calls as working until this is implemented and tested.

## Remaining dashboard security action

Supabase Security Advisor currently reports leaked-password protection disabled. Enable it under Authentication → Settings → Password Security, then rerun the Security Advisor:
https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
