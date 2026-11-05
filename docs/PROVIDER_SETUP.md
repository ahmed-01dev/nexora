# NEXORA provider and key setup

## Supabase client

The Flutter client is configured with the active project URL and a Supabase **publishable** key. These values are intentionally public and are safe to ship in Android/Web clients when Row Level Security is correctly enabled. The repository never contains a `service_role` or Supabase secret key.

The build workflow also accepts optional GitHub Actions secrets named `SUPABASE_URL` and `SUPABASE_ANON_KEY`; if they are absent, it uses the public client configuration already checked into the project.

## WhatsApp OTP

The UI selects WhatsApp by default and passes `OtpChannel.whatsapp` to Supabase Auth. Real delivery still requires a Twilio Verify WhatsApp sender configured in the Supabase Dashboard:

1. Open Authentication → Sign In / Providers → Phone.
2. Enable phone authentication.
3. Configure Twilio Verify as the phone provider.
4. Add the Twilio Account SID, Auth Token, Verify Service SID, and approved WhatsApp sender/template in the provider configuration.
5. Keep all Twilio credentials in Supabase's provider secret settings. Never add them to Flutter, GitHub source, or chat messages.
6. Test signup, login, resend, and invalid/expired OTP flows with a real phone.

Until this is completed, the app's WhatsApp choice is wired in code but real message delivery is not verified. SMS remains available as the selectable fallback.

## Push notifications

The in-app notification center and per-category in-app preferences are implemented. Push delivery is not enabled. It requires a Firebase project, Android app registration, Firebase Messaging configuration, secure server-side credentials, and a server-side delivery function. Do not place Firebase Admin credentials in the Flutter app.

## Voice and video calls

The database contains call signaling records only. Production WebRTC requires a signaling lifecycle, TURN infrastructure, server-only TURN credentials, call push delivery, permission handling, and real-device multi-network tests. STUN-only testing is not sufficient for a global production service.

## Remaining dashboard security action

Supabase Security Advisor currently reports leaked-password protection disabled. Enable it under Authentication → Settings → Password Security, then rerun the Security Advisor.
