# AFRICA LINK v1.3 — Release Engineering & QA

**Tagline:** Connect Africa. Build Africa.

AFRICA LINK is a pan-African youth network foundation covering social connections, communities, messaging, opportunities, education, business, funding, projects, notifications, safety, verification, AI/translation and administration.

## v1.3 additions
- static release audit script (`scripts/release_audit.py`);
- explicit release checklist covering source, Supabase, application flows and mobile builds;
- release-contract Flutter test;
- version `1.3.0+15`.

## v1.2 additions
- private media asset registry and signed-URL service foundation;
- push-device registration and notification preference controls;
- content-reporting RPC and user-owned report access;
- server-side push notification boundary via Supabase Edge Function;
- production deployment/operations checklist;
- environment separation and release-gate documentation;
- version `1.2.0+14`.

## Migration order
`001_core.sql` -> `002_remaining_modules.sql` -> `003_functional_hardening.sql` -> `004_integration_core.sql` -> `005_platform_experience.sql` -> `006_advanced_social_collaboration.sql` -> `007_full_platform_integration.sql` -> `008_release_hardening.sql` -> `009_production_readiness.sql` -> `010_admin_privacy_deployment.sql` -> `011_final_production_systems.sql`

## Validation status
This package has been statically reviewed and its archive can be checked for integrity. The current environment does not provide the Flutter SDK, so `flutter analyze`, `flutter test`, and a release build cannot truthfully be reported as executed here.

Production deployment additionally requires environment-specific Supabase RLS/storage review, private storage bucket configuration, Edge Function secrets, push provider setup, AI/translation/payment provider setup, backups, monitoring, legal/privacy review, and end-to-end smoke tests.

See `docs/DEPLOYMENT.md` for the final deployment gate.
