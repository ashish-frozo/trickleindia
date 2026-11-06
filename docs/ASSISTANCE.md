# Grounded assistance and voice navigation

The current baseline provides app-help retrieval, not open-ended financial advice or autonomous transactions. English/Hindi content is still draft. Four bundled cards cover saving contributions, sync, enterprise expenses and requesting support. The assistant quotes source titles/steps and displays card ID/version. Offline operation uses cached/bundled instructions. Unsupported topics return no answer rather than invented guidance.

## Optional model-assisted matching

`POST /v1/assistant` requires a session and `{question,language,remoteConsent}`. Language is en/hi, question is bounded to 500 characters, and consent defaults false. The endpoint is limited to 12 requests/minute per IP. It releases database connections before external inference and checks the session again before returning the result.

Configure all of `ASSISTANT_ENDPOINT` (HTTPS chat-completions URL), `ASSISTANT_API_KEY` and `ASSISTANT_MODEL` privately. No model or paid account is selected automatically. The request uses system/user messages, `store:false` and a bounded completion. The model may return only up to two known card IDs. The server never renders model prose, executes tools, changes records or accepts financial amounts. Unknown citations, invalid/oversized responses, redirects, timeout and provider failures fall back to local matching. A provider can still select an irrelevant existing card; field evaluation remains required.

The user must opt in for each help session before a question and help corpus can leave the service. Do not enter names, phone numbers or account records. No member records, tokens or conversation history are included in the provider request. Production logs omit request bodies. Do not interpret `store:false` as a guarantee covering every provider's retention policy; approve the chosen service before activation.

Adapter reference: [OpenAI Chat API](https://developers.openai.com/api/reference/resources/chat). It uses a compatible request shape, not a claim that any arbitrary service or model was live-tested. Local tests use mock transport, check consent, citation restrictions, failure fallback and URL constraints. No real provider call has been made.

## Voice navigation

Open Help and voice navigation from Help or Capabilities. Type a screen name, or choose Use microphone and accept the explanation. The platform recogniser is requested to operate on device; platform/browser availability and processing differ, so offline recognition is not promised. Exact recognised commands are reviewed before pressing Open selected screen. There is no automatic route change on speech, continuous recording, financial entry, or automatic confirmation.

Supported commands: home/help/sync for all roles; groups/meetings/work for staff; reports/activity for managers. Hindi equivalents are shown in the interface. Role-restricted and ambiguous commands are rejected. Microphone sessions are bounded and cancelled when leaving the page or backgrounding. Text commands remain available if permission, locale or recognition is unavailable.

Uses pinned `speech_to_text` 7.5.0, following its [permissions and lifecycle guidance](https://pub.dev/packages/speech_to_text) and [listen options](https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechToText/listen.html). Actual spoken recognition on representative devices remains a field verification task.
