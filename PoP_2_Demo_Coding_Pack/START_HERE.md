# PoP 2.0 demo coding pack

Version 1.0 • 2026-11-05 • Frozo Software Private Limited

Build a polished, runnable proposal demonstration for Trickle Up India Foundation. The central proof is an SHG contribution saved on an Android device without connectivity, preserved across process termination, synchronised once, and reflected in a member passbook and a programme web portal.

This pack fixes a demonstration scope. TUIF's approved BRD, production rollout size, and final language acceptance criteria remain outstanding. The source tender requires five languages, Flutter mobile and web, Node.js, and production hosting in TUIF's AWS account. The prototype decisions below are Frozo's recommendations for this build.

## Start the coding agent

Paste [AGENT_TASK.md](AGENT_TASK.md) into the coding agent with this entire folder available. Keep the supplied JSON and ARB files beside the documents. Build the application in the parent project directory while preserving this specification folder.

## Read in this order

1. [01_DEMO_PRD.md](01_DEMO_PRD.md) defines scope, priorities, actors, and user journeys.
2. [02_UI_UX_SPEC.md](02_UI_UX_SPEC.md) defines the visual language, screens, components, and interaction states.
3. [03_ARCHITECTURE_AND_SYNC.md](03_ARCHITECTURE_AND_SYNC.md) defines persistence, boundaries, synchronisation, and recovery.
4. [04_DATA_AND_API_CONTRACT.md](04_DATA_AND_API_CONTRACT.md) defines entities, arithmetic, endpoints, and errors.
5. [07_CONTENT_AI_AND_WHATSAPP.md](07_CONTENT_AI_AND_WHATSAPP.md) defines the content and integration behaviours.
6. [05_IMPLEMENTATION_PLAN.md](05_IMPLEMENTATION_PLAN.md) provides ordered work packages and completion gates.
7. [06_ACCEPTANCE_AND_DEMO.md](06_ACCEPTANCE_AND_DEMO.md) defines verification and the presentation script.
8. [08_SOURCES_AND_DECISIONS.md](08_SOURCES_AND_DECISIONS.md) records provenance, assumptions, and production gaps.

## Deliverable boundary

| Area | Build decision |
| --- | --- |
| Core runtime | Flutter Android, Flutter web portal, Node.js/TypeScript API, PostgreSQL |
| Primary demonstration | Real offline savings entry, restart, synchronisation, passbook, dashboard |
| Secondary demonstration | Principal repayment, enterprise expense, Smart Sakhi support workflow |
| UI languages | English and Hindi, with expansion-ready message resources |
| Audio | A small set of bundled, reviewed instructional clips when assets can be produced and checked |
| Knowledge help | Working retrieval of bundled illustrative help cards, labelled Demo help |
| Conversational AI | Optional live provider extension after core acceptance, accurately labelled |
| WhatsApp | Local chat simulator connected to real demo support records, visibly labelled Simulation |
| Authentication | Restricted demo identities with server-enforced permissions |
| Hosting | Local development and recording. An access-controlled deployment is a separate operational step |
| Data | Synthetic records only, with deterministic balances and reset instructions |

The agent must implement P0 and P1 in the implementation plan. P2 is an optional extension. A missing P0/P1 capability must appear as a blocker in the handoff. Avoid silently promoting P2 into the required scope.

## Canonical files

- [assets/demo_seed.json](assets/demo_seed.json) owns fixture identity and expected arithmetic.
- [assets/design_tokens.json](assets/design_tokens.json) owns colours, spacing, radii, and typography tokens.
- [assets/ui_en.arb](assets/ui_en.arb) and [assets/ui_hi.arb](assets/ui_hi.arb) provide initial UI copy. Extend them consistently.
- [assets/content_cards.json](assets/content_cards.json) provides illustrative help content and audio scripts.

For numeric fixture disagreements, follow demo_seed.json and repair the referring text. For application rules, follow the PRD and data contract. For sync behaviour, follow the architecture document. Record any necessary deviation in IMPLEMENTATION_NOTES.md with its reason and test evidence.

See [PACK_VALIDATION.md](PACK_VALIDATION.md) for checks already run on these specifications and assets. Application acceptance tests remain the implementing agent's responsibility.

## Completion evidence

Deliver source, pinned dependency locks, database migrations, a local startup guide, Android APK, web build, automated test results, screenshots, a recording of the main journey, and a truthful capability matrix. Build outputs are produced by the coding agent. This pack contains specifications and supporting fixtures.

Suggested user-facing title is PoP 2.0. Display Proposal demo • Fictional data in both applications. Use TUIF's name as project context. Brand marks require an approved supplied asset.
