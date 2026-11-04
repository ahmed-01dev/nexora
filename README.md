# NEXORA

NEXORA is a privacy-conscious social platform project designed for Android and web.

## Project status

- Product direction: friends and followers, mixed media feed, short-form video, encrypted messaging, and location-based discovery.
- Backend: Supabase (project configured separately; never commit secrets).
- Budget constraint: zero-cost development using free tiers where practical.
- Primary development workflow: Android device and GitHub.

## Repository structure

The application scaffold and implementation will be added in subsequent commits. Keep credentials, service-role keys, signing keys, and private user data out of source control.

## Security principles

- Enforce authorization on the backend, not only in the client.
- Keep Row Level Security enabled for user data.
- Use least-privilege database grants and storage policies.
- Do not claim end-to-end encryption until key management and protocol implementation have been independently reviewed.

## Development

Implementation details and setup instructions will be documented here as the Flutter app and CI workflows are added.
