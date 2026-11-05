# Content, voice and WhatsApp

## Product intent

Help a participant understand the app, record a support need, and reach her assigned Smart Sakhi. For this proposal, a visible support workflow demonstrates how communication leads to accountable follow-up. Financial records continue through the authenticated app and authoritative ledger.

## Language contract

English and Hindi cover the required demo screens, navigation, form labels, errors, sync states, accessibility labels and capability labels. ARB files are starter resources; the agent must extract every added visible string and keep both locales complete. Use locale-aware number/date formatting. Currency amounts must preserve exact paise independently of display formatting.

Hindi resources in this pack are draft copy, supplied for implementation. Arrange a fluent reviewer before client-facing recording and record the review status. TUIF's approved terminology is unavailable. Use consistent terms and plain sentences. Member names remain as entered, with no automatic name translation.

Odia, Ho and Santhali are production requirements in the tender. Their UI translations, fonts, audio, dialect handling and field acceptance are separately planned. Do not offer a working language switch to untranslated screens. A planned-language row may explain the roadmap.

Language availability must be tracked separately for UI, transcription, translation, text-to-speech and content approval. A translation model listing for a language does not establish that speech recognition or speech generation is supported.

## Offline help cards

Use assets/content_cards.json. It contains short bilingual, illustrative app instructions: save a contribution, understand sync, record an expense and ask a Sakhi. Each card has a stable ID, version, reviewStatus, locale text, keywords and an audio script. These describe the proposed demo behaviour and are not TUIF-approved programme advice.

Offer topic tiles and simple keyword search. Return a card with title, steps and source label Demo app instructions. Unknown topics return “I do not have approved guidance for that. Ask your Smart Sakhi.” Offer a support request. This is deterministic retrieval; label it Demo help. A scripted answer must not be labelled as a live AI response.

Bundle content locally, including a small search index. The server may supply the same versioned pack at bootstrap. Content updates install atomically. App operation remains usable when content retrieval fails.

## Audio

Each card can have a short English/Hindi instructional clip. Assets must be intelligible, accurate against the approved script and reviewed for pronunciation and pacing. Use licensed human recording or a permitted TTS provider; do not imitate a real person's voice. Bundle the small accepted clips for offline playback and retain source/licence metadata. Provide play, pause and replay, with no autoplay and with the text always available.

No audio files are included in this specification pack. JSON audioAsset values are null. The coding agent may create clips if authorised services are already available, then replace null paths and mark individual clips reviewed only after actual review. Otherwise display Audio preview unavailable, keep text help functional and document the audio gap. Never wire a button that pretends to play a missing clip.

## Optional P2 spoken expense draft

An explicit microphone action records a short clip, shows recording state and offers cancel. Use a bounded duration, for example 20 seconds, and discard local temporary audio after processing/cancellation. Do not start background recording. Provider requests go through the backend; keys never enter Flutter or web bundles.

The user may say “Spent three hundred and fifty rupees on seeds.” The provider response is a draft with amountPaise35000, category seeds, recognisedText, language and confidence/uncertainty metadata when the provider supplies it. The app shows the transcript, amount and category for correction. The user must select Confirm expense before a normal transaction operation is created. If the number, language or intent is uncertain, require manual entry. No model call can directly post to the ledger.

The required offline implementation uses typing. Optional speech is visibly online-only unless an actual on-device recogniser is implemented and tested. An outage preserves the editable form and offers typing. Do not call an online speech provider from airplane mode and present the result as offline AI.

Provider research suggests English/Hindi/Odia speech options and separate Santhali candidates; Ho needs further validation. Verify current model documentation, licences, processing locations, pricing and real sample quality before choosing. This pack makes no production provider commitment.

## Optional P2 grounded assistant

Use only an explicitly versioned and reviewed knowledge corpus, restricted to authorised content. Show the source card/version for an answer. Low-confidence or unsupported requests escalate to the assigned Sakhi. For production, knowledge approval belongs to TUIF. For the demo, use illustrative app instructions with their draft label.

Retrieval text and user messages are untrusted data. They cannot change system rules, expose tokens, query other members, or execute writes. The assistant has no financial mutation capability. Test unsupported questions, adversarial instructions, wrong-language requests and provider timeouts. Apply bounded input/output lengths and record operational metrics without copying sensitive text into logs.

## Required WhatsApp simulation

X01 is an embedded simulated conversation in the portal, labelled WhatsApp simulation • No messages sent. Use a simple original chat layout and generic phone frame if desired. Avoid a fabricated WhatsApp verified badge or an exact brand replica.

Server-owned contact demo-contact-rani maps to Rani. The simulator requires manager access and provides a small topic menu. Choosing expense_help emits a unique simulatedMessageId. The backend creates one support request assigned to Kavita, returns its reference and a scripted acknowledgement. Replay must reuse the ID to demonstrate deduplication. Manager status changes flow into the support queue through the same backend as app-created tickets.

The scripted acknowledgement says the request was recorded and who is assigned. It must not say a Sakhi has read or resolved it until the corresponding action exists. After actual demo resolution, a refresh may show the recorded resolution as a simulated follow-up. Every displayed chat bubble remains inside the simulation frame.

Keep the value proposition concrete: a participant can ask for assistance and staff can track whether it was addressed. Measure request creation, assignment, first staff action and resolution. Do not promise reduced costs or higher engagement without a pilot baseline.

## Optional official WhatsApp test connection

Use an official Business Platform integration through an approved provider or Meta API. Recheck current onboarding, messaging permissions, template rules, service-window rules, rate limits and commercial charges at implementation. Do not automate a personal WhatsApp session or connect an existing account without explicit authorisation.

Production scope must cover organisational account ownership, permitted test contacts, inbound signature verification, secret management, webhook event deduplication, asynchronous acknowledgement, retry handling, delivery state, user preferences/opt-out, staff handover and support ownership. A delivery status is not proof that the participant understood or acted.

Proactive reminders and campaign messages are deferred. Do not include savings/loan balances or sensitive household information in notifications by default. A phone number alone is insufficient authorisation to reveal participant records. Start with a minimal help intake flow and validate consent/identity requirements with TUIF before expanding.

Treat live integration build cost and provider/message usage as separate proposal line items. Demo simulation is included in the prototype. Production WhatsApp should be a scoped option unless TUIF explicitly includes it in the agreed baseline.
