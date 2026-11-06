# Reserved attachment boundary

The demo intentionally does not upload attachments. Future attachment work must remain separate from financial mutation acknowledgement.

Proposed interface: prepareUpload(ownerType, ownerId, mediaType, byteLength, sha256) returns an upload ID and bounded upload authorization; completeUpload(uploadId, sha256) verifies stored bytes and scan status; listAttachments(ownerType, ownerId) returns authorised metadata; downloadAttachment(attachmentId) returns short-lived read authorization; deleteAttachment(attachmentId, expectedVersion) applies retention rules and an audit record.

Client state: local-only → queued → uploading → scanning → available, or retryable/rejected. Metadata carries actor/dataset ownership, content hash, byte size, MIME type and independent operation ID. Never embed file data in the financial outbox. Reject unsupported types and oversized files; store outside publicly readable paths. File visibility follows the parent entity's server-enforced scope. No endpoint or upload capability is advertised by the current client. Storage, scanning, retention and size limits require implementation and acceptance before enabling uploads.
