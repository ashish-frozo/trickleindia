# Coding agent task

Act as the senior Flutter and backend engineer responsible for this PoP 2.0 proposal demo. Read START_HERE.md and all linked specifications before changing application code.

Implement every P0 and P1 work package in 05_IMPLEMENTATION_PLAN.md, in its dependency order. Build the end-to-end offline contribution flow first. Use the supplied fixtures and design tokens. Resolve ordinary implementation choices autonomously and document them. Inspect existing source before scaffolding and preserve unrelated work.

Use Flutter for Android and the programme web portal, Node.js with TypeScript for the API, and PostgreSQL for the server database. Use Drift with encrypted SQLite for native offline storage. Select mutually compatible stable dependencies from current official documentation and pin resolved versions. The acceptance tests must exercise the selected versions.

Implement real persistence, API calls, permission checks, retry deduplication, and reporting. Show a separate pending contribution amount until the server accepts a transaction. Protect the core workflow against process termination and lost acknowledgements. All financial amounts use integer paise.

Make the UI follow 02_UI_UX_SPEC.md, including its screen composition, accessibility, responsive rules, and language behaviour. Complete each screen's loading, empty, validation, offline, failure, and success states. Render screenshots on an Android device or emulator and in a desktop browser. Fix overflow, weak hierarchy, inaccessible controls, and inconsistent status wording before handoff.

The bundled knowledge cards are illustrative app help. The WhatsApp surface is a labelled simulator creating real demo support requests. Keep these labels visible. A live AI or WhatsApp integration is P2 and depends on provider setup and the checks described in 07_CONTENT_AI_AND_WHATSAPP.md.

Run the acceptance suite in 06_ACCEPTANCE_AND_DEMO.md. Test real network interruption as well as controlled fault injection. Deliver commands that another engineer can run from a clean checkout. Include the tested toolchain, fixtures, migration process, reset process, screenshots, recording, and known gaps in IMPLEMENTATION_NOTES.md.

Use synthetic data throughout. Keep demo authentication and reset endpoints restricted to the configured demo environment. Any public deployment, third-party account creation, live message sending, purchase, or production connection needs separate user authorisation. Continue local implementation and independent tests if a provider credential is absent.

The final handoff must state which P0/P1 tests passed, which could not run, what is simulated, and how to reproduce the demonstration. Do not claim feature completion from compilation alone.
