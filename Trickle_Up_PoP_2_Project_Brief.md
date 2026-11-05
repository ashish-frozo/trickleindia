# Trickle Up PoP 2.0: Project Brief
Updated 5 November 2026 | Frozo Software Private Limited

## Purpose and status
Working reference for evaluating a possible proposal to Trickle Up India Foundation (TUIF). No bid has been submitted and no contract awarded. Independent confirmation of the specific tender remains pending; the global office has acknowledged our enquiry automatically.

**Deadline: Monday 9 November 2026, 5:00 pm IST.** Client reaffirmed this on 5 November.

## Project overview
PoP 2.0 is a mobile app and web portal for rural women’s self-help groups (SHGs), small enterprises, Smart Sakhis and programme staff. It should work in low-connectivity environments and be usable by people with limited literacy or digital experience.

Users: SHG members, community helpers called Smart Sakhis, field teams, and programme managers/administrators. A field worker recording information offline and synchronising later is an illustration, not an approved detailed workflow.

## Phase 1 scope
The ToR identifies five modules for FY 2026–27:
1. User registration and profiling.
2. SHG management.
3. SHG financial management.
4. Enterprise management.
5. Smart Sakhi monitoring.

AI voice assistant and chatbot are common across all three phases and may grow progressively. Exact Phase 1 AI functionality and acceptance criteria remain unspecified. Cluster management, market linkages and advanced analytics are part of the broader vision, not automatically fully defined Phase 1 deliverables.

## Technical requirements
- Flutter mobile app and web frontend; Node.js backend and APIs; deployment in TUIF's AWS account.
- Firebase Authentication or Amazon Cognito, selected by TUIF during design.
- Save and access relevant data offline; automatically sync on reconnection, prevent duplication, handle conflicts, and show pending/success/failure status. Exact offline boundary for AI and voice is unknown.
- Five languages: English, Hindi, Odia, Ho and Santhali. Clear visual cues, minimal typing, voice-assisted navigation and audio instructions for low-literacy users.
- Client clarification: the vendor is primarily responsible for translation and voice-over in all five languages; TUIF supports language validation.

## Delivery and handover
Requirements finalisation, work plan, workflows, UX/UI and wireframes, database/API/architecture design, app, portal, backend, demonstrations, functional/integration/regression tests, UAT, security remediation, development/UAT deployment, production scripts and rollback instructions, full source code and documentation, system overview presentation and knowledge transfer. TUIF must be able to deploy and maintain independently. Bidder proposes warranty/support; duration is not fixed in the reviewed ToR.

## Commercial and proposal
Separate technical and financial PDFs. Financial proposal in INR including applicable taxes, with development, professional fees, AWS, AI subscriptions and incidental costs. Technical proposal to describe company, understanding, approach, timeline, team/CVs, relevant experience and examples.

Client says Frozo’s own completed products and team members’ prior experience may be cited, clearly separated from client assignments delivered by Frozo. Do not imply previous employers’ work was delivered by Frozo.

Payment milestones, subject to approval: 20% requirements/work plan; 20% design/architecture; 30% agreed Phase 1 modules demonstrated; 20% testing/UAT and production readiness; 10% source, documentation, presentation and knowledge transfer. No budget or fixed delivery duration verified.

Advertised submission: rbehera@trickleupindia.org, CC nbasista@trickleupindia.org. Independent confirmation of tender and addresses is pending. No CVs, references, price or proposal have been submitted.

## Open questions and risks
- Detailed workflows, financial fields, reports, user permissions and acceptance criteria. Client will not share BRD/module specifications/wireframes before submission; proposal must use ToR.
- User count, device/platform requirements, usage and data volumes.
- Existing PoP application code reuse, data migration and integrations.
- Offline boundaries, conflict rules, shared devices, data loss and recovery.
- Exact Phase 1 AI capability, language quality, model/provider, inference cost and offline voice requirements.
- Translation content, language variants, voice recording volumes, revision rounds and validation responsibilities.
- Security, privacy, retention, backups and recovery requirements.
- Schedule, review turnaround, warranty and ongoing support costs.

## Next steps
1. Verify tender authenticity and amendments through the independently identified organisation.
2. Decide whether Frozo should bid; assess Flutter/offline, team capacity and language-delivery capability.
3. Build a ToR compliance checklist and gather truthful product and team evidence.
4. Define explicit scope, assumptions, exclusions, dependencies, acceptance and change control.
5. Estimate translation, voice, offline synchronisation, AI, AWS and support costs before a separately approved financial proposal.

Keep confirmed requirements, client clarifications, estimates and assumptions separate. Date and link later updates.

## Sources
- Terms of reference: https://www.samsstc.com/Uploads/Rfp/RfpDocuments/RfpDocuments_6a117cf26110482d92618ed039e0786d.pdf
- Client clarification, 5 November: https://mail.zoho.in/zm/#mail/folder/7670783000000002014/p/1793875028939110100
- Existing PoP app: https://play.google.com/store/apps/details?hl=en&id=com.tickleuppop
