# NEXORA Firebase Cloud Messaging setup

Android FCM registration and delivery are implemented with Firebase Installation IDs (FIDs).

## One-time server secrets

In Supabase Dashboard → Edge Functions → Secrets, add:

- `FIREBASE_SERVICE_ACCOUNT_JSON`: the complete JSON contents of a Firebase service-account private-key file for the NEXORA Firebase project. Create it in Firebase Console → Project settings → Service accounts → Generate new private key. Grant the service account permission to send Firebase Cloud Messaging messages. Never put this JSON in GitHub or in the Flutter app.
- `NEXORA_PUSH_WEBHOOK_SECRET`: the one-time shared secret stored in Supabase Vault under `nexora_push_webhook_secret`. Obtain its value from the project owner and add it as an Edge Function secret.

The database trigger calls the deployed `send-push-notification` Edge Function using the Vault secret. The function checks the recipient's global and per-category push preferences, loads that recipient's Android devices, and sends FCM messages using the server-side service account.

## Android setup

The build workflow copies `firebase/android/google-services.json` into the generated Android app folder, configures the Google Services Gradle plugin, adds notification permission, and enables Firebase Installation ID registration. Do not commit a Firebase service-account private key.

## Security

- The client only stores its own FID in `public.user_devices`, protected by existing owner-only RLS policies.
- The Firebase service-account key remains in Supabase Edge Function secrets.
- The database-to-function shared secret remains in Supabase Vault and Edge Function secrets.
- The function rejects unauthenticated client requests; the database webhook uses the shared secret.
