# Sources, decisions and open information

Prepared 2026-11-05. This pack combines the local tender, the project brief and official technical documentation. Recommendations are Frozo's prototype design decisions. Source requirements and recommendations must remain distinguishable in the proposal.

## Primary project evidence

| Source | Supported fact and limitation |
| --- | --- |
| Local RfpDocuments_6a117cf26110482d92618ed039e0786d.pdf, Terms of Reference | Flutter mobile/web, Node.js, TUIF AWS, five Phase 1 modules, offline/sync, five languages, progressively enhanced AI, testing and handover requirements. The complete approved BRD is not supplied |
| Local Trickle_Up_PoP_2_Project_Brief.md | Consolidated client clarifications, submission context and proposal planning. Email-derived statements are attributed to this brief; the email thread was not reverified during pack preparation |
| TUIF MPOWERED evaluation [1] | Field context includes usability and connectivity friction around login, typing/voice and content download. These motivate small offline bundles and assisted entry; they do not establish the exact new app workflow |
| TUIF digital-agency report [2] | Qualitative evidence of shared-device access and uneven digital agency. Supports separating actor/participant and testing session switching; does not prove a universal device-use pattern |

The brief records proposal submission on 2026-11-09 at 17:00 IST with technical and financial PDFs, financial values in INR including taxes. Validate against the latest client communication before submission. A newly completed custom demo is not a stated tender prerequisite. Do not delay the proposal merely to finish optional integrations.

## Decisions for this demo

| Decision | Why | Production follow-up |
| --- | --- | --- |
| Android app plus Flutter web portal | Focuses the field and management workflows within the tender stack | Confirm Android versions, device fleet and any additional platform needs |
| English/Hindi implemented; other three planned | Allows a coherent bilingual demonstration with explicit scope | Native review, dialect testing, font/audio coverage for all five languages |
| Offline-first local database and narrow outbox | Makes restart, retry and confirmation behaviour demonstrable | Evaluate scale, conflict rules, sync platform ownership and operations |
| Serialized demo write cursor | Prevents cursor/commit races in a small dataset with inspectable code | Rework throughput strategy only with equivalent consistency guarantees |
| No financial approval state | Avoids inventing an unconfirmed approval hierarchy | Obtain TUIF's actual maker/checker and corrections policy |
| Principal-only loan model | Clear auditable demonstration with known fixtures | Confirm interest, schedules, penalties, opening balances and bookkeeping rules |
| Demo cash surplus | Accurate for cash sales minus expenses in the supplied scope | Define profit, inventory and receivables separately if required |
| Restricted synthetic demo identity | Allows repeatable roles without committing TUIF's production identity | TUIF selects Firebase/Cognito and production onboarding/recovery |
| Labelled deterministic help | Demonstrates offline assistance without implying a live model | Approved corpus, live provider evaluation, language quality and cost |
| WhatsApp simulator plus real support workflow | Shows accountable follow-up while keeping setup independent | Optional live platform scope, account ownership, consent and operating cost |
| Small native encrypted cache | Reduces exposure on shared devices and enables offline work | Device policy, revocation limits, retention, key management and security review |

## Missing information to resolve before production commitments

1. Approved BRD, wireframes, exact actor permissions and who approves financial corrections.
2. Participant/SHG/device counts, connectivity patterns, Android versions and expected concurrency.
3. Authoritative savings/loan/accounting definitions, migrations and existing-system integration rights.
4. Approved content, terminology, language reviewers, dialects and audio accessibility expectations.
5. TUIF AWS/identity standards, retention requirements, incident/support ownership and acceptance sign-off.

LokOS is a relevant SHG ecosystem reference [12]. No authorised API contract or integration access has been supplied. Do not promise an integration or mirror its data through scraping.

## Source links

Accessed or reviewed 2026-11-05. Provider pages are mutable; implementation must recheck selected dependencies and policies.

1. TUIF, MPOWERED Social Return on Investment: https://trickleup.org/wp-content/uploads/2024/07/MPOWERED-Social-Return-on-Investment.pdf
2. TUIF, Understanding Digital Agency: https://trickleup.org/wp-content/uploads/2026/07/Trickle-Up-Report-on-Understanding-Digital-Agency.pdf
3. Flutter offline-first architecture: https://docs.flutter.dev/app-architecture/design-patterns/offline-first
4. Drift encryption: https://drift.simonbinder.eu/platforms/encryption/ and migrations: https://drift.simonbinder.eu/migrations/
5. Flutter accessibility: https://docs.flutter.dev/ui/accessibility
6. Flutter internationalisation: https://docs.flutter.dev/ui/internationalization
7. Sarvam model catalogue: https://docs.sarvam.ai/api/getting-started/models
8. BHASHINI model catalogue: https://dibd-bhashini.gitbook.io/bhashini-apis/available-models-for-usage
9. OWASP Mobile Application Security Verification Standard: https://mas.owasp.org/MASVS/
10. WhatsApp Business messaging policy: https://business.whatsapp.com/policy and platform pricing: https://business.whatsapp.com/products/platform-pricing
11. PowerSync conflict handling, evaluated as a future option: https://docs.powersync.com/handling-writes/handling-update-conflicts
12. LokOS official portal: https://lokos.dord.gov.in/home
13. OWASP prompt injection risk: https://genai.owasp.org/llmrisk/llm01-prompt-injection/
14. AI4Bharat ASR: https://github.com/AI4Bharat/IndicConformerASR ; TTS: https://huggingface.co/ai4bharat/indic-parler-tts ; translation: https://github.com/AI4Bharat/IndicTrans2
15. Tender source: https://www.samsstc.com/Uploads/Rfp/RfpDocuments/RfpDocuments_6a117cf26110482d92618ed039e0786d.pdf

## Proposal-use guidance

Present the demo as evidence of offline reliability, accessible interaction and accountable support. Use measured test results and actual screenshots after implementation. Describe optional AI/WhatsApp work as separately scoped capability. Attribute Frozo products, prior employment work and this new prototype accurately. Avoid implying this synthetic demo is an existing TUIF deployment or a completed production implementation.
