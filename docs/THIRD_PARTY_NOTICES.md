# Third-party notices

Noto Sans and Noto Sans Devanagari are bundled under the SIL Open Font License in `packages/ui/assets/fonts/OFL.txt`. Font files came from the official notofonts/noto-fonts repository. Material icons are bundled through Flutter.

Flutter/Dart, Riverpod, go_router, Drift, sqlite3/SQLite3MultipleCiphers, flutter_secure_storage, path_provider, HTTP, UUID, intl, Fastify, Zod and PostgreSQL are implementation dependencies. Exact resolved versions are in the dependency locks. Retain the Flutter-generated web `assets/NOTICES` and native bundled notices when distributing builds. npm package licence files remain in installed dependencies/container layers.

The Android profile APK for local demonstration uses a development signing configuration. A customer production release requires its own approved signing and HTTPS environment. Neither signing keys nor locally generated access codes belong in the source package.

The supplied bilingual help and copy remain draft demo content requiring field terminology review. No TUIF logo or brand asset was supplied or fabricated.

The generated Unicode full case-fold mapping uses the Unicode 17 CaseFolding data. The applicable Unicode licence is retained at `services/api/UNICODE-LICENSE.txt`.

## Requirements follow-up dependencies

Added `aws-jwt-verify` 5.2.1 for Cognito access-token verification and `flutter_appauth` 13.0.0 for native PKCE sign-in. `web` 1.1.2, `http` 1.6.0 and `crypto` 3.0.8 support browser authentication/export. Exact dependencies and transitive licences are represented in their pinned lockfiles and package notices. PowerPoint generation uses development-only PptxGenJS, Playwright, Sharp and the html2pptx skill; these are not bundled in the app runtime. No paid identity, AI, speech or messaging service has been activated.

Voice navigation adds pinned `speech_to_text` 7.5.0 and its platform packages. Generated runtime notices retain their licences. Device speech services are optional dependencies; no recognition or recording provider account was activated.
