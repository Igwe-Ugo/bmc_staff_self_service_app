# Rewiring chat attachments for the mobile app

Addendum to `SOCKET_INTEGRATION.md`, covering the change in commit `09c5729`
*"chat documents storage changed to cloud storage"*. Everything else in that
document still stands — this replaces its attachment paragraph only.

---

## 1. What changed

Attachments used to travel inside the socket message as base64. They now live in
the external document store and the message carries only a reference.

| | Before | After |
|---|---|---|
| Wire field | `file.data` — base64 bytes | `file.documentKey` — an id |
| Where bytes live | Inline in the message, in Redis history, in every roster payload | External document store |
| How a client reads them | Already had them | `GET /api/messaging/attachment?documentKey=…` |
| Access control | Implicit — bytes only ever reached participants | Explicit Redis grant, `chatdoc:{documentKey}` |
| Lifetime | Forever, inside the message | **7 days**, then reaped |

**The breaking part for the mobile app:** `server.ts` now relays a `file` only
when `file?.documentKey` is present.

```ts
// server.ts — process-send-message
if (file?.documentKey) {
    message.file = { name: file.name, type: file.type, size: file.size, documentKey: file.documentKey };
}
```

A client that still sends `{name, type, size, data}` gets **no error at any
layer**. The message is accepted, persisted and delivered — with the `file`
stripped. The sender sees their attachment disappear into a text-only message
and nothing anywhere reports a problem. This is the single most important
consequence of the change.

---

## 2. The new flow

Three steps, in this order. The upload must complete before the message is sent.

```
 1. POST /api/corporate-documents/upload        → { data: { documentKey } }
 2. socket emit "process-send-message"          → file: { name, type, size, documentKey }
 3. GET  /api/messaging/attachment?documentKey= → raw bytes
```

### Step 1 — Upload

`POST /api/corporate-documents/upload`, JSON body:

| Field | Value | Notes |
|---|---|---|
| `fileName` | original filename | |
| `mimeType` | e.g. `image/jpeg` | falls back to `application/octet-stream` |
| `docSize` | **raw** byte count | not the base64 length |
| `base64` | **full data URL** | see §5 — this is not bare base64 |
| `title` | the filename again | what the web sends |
| `description` | `BMC-CHAT-ATTACHMENT` | **load-bearing** — see §5 |

Success is `201` with:

```json
{ "data": { "id": "…", "documentKey": "…", "fileName": "…" },
  "message": "Document uploaded successfully", "toast": "success" }
```

There is no chat-specific upload route. The corporate-documents route is reused
deliberately — the passcode handshake, the Redis TTL and the metadata rollback
on storage failure are already correct there, and the storage service only
accepts authenticators it already knows (`corpDoc_upload`).

### Step 2 — Send

Unchanged except for the `file` shape:

```dart
file: { 'name': …, 'type': …, 'size': …, 'documentKey': … }
```

The server writes the access grant **before** it emits the message, so a
recipient that fetches the attachment the instant it renders will not race the
grant.

### Step 3 — Download

`GET /api/messaging/attachment?documentKey=<key>` — optionally `&download=1`,
which only flips `Content-Disposition` to `attachment`; irrelevant on mobile,
where you hold the bytes either way.

| Status | Meaning | Mobile should |
|---|---|---|
| `200` | raw bytes, with `Content-Type` and `Content-Length` | render / save |
| `404` | past retention, or its message was deleted for everyone | show "no longer available" — **an expected state, not an error** |
| `403` | caller is not a participant in that conversation | show a permission message; do not retry |
| `401` | token rejected | the AuthInterceptor should have refreshed already; treat as session dead |
| `5xx` | document store failed | retryable |

---

## 3. Why these web-first routes work from the app

Both routes call `await auth()` — the wrapper in `lib/configs/auth/auth.ts`, not
NextAuth's own. That wrapper resolves the session cookie first and **falls back
to `Authorization: Bearer`** via `getBearerSession()`. The app's Dio client
already attaches that header on every request, so no server change is needed and
no `X-API-Key` is involved.

One detail matters. The attachment route resolves the caller as:

```ts
const currentUserId = session.user.username as string;
```

Grants are written from `socket.data.userId`, which — as `SOCKET_INTEGRATION.md`
§0 explains at length — **is the username**. Both sides therefore agree, and the
mobile app needs to do nothing special. But it is the same identity trap in a
third place: if anything downstream ever compares against `user.id`, it fails
closed for every user, including the sender.

---

## 4. Who can read an attachment

The document store's own stream endpoint only checks that the caller is
authenticated — it has no idea which conversation a document belongs to. Without
an extra gate, any signed-in user holding a key could read any attachment, which
would be a regression against the old inline design where bytes only ever
reached participants.

So the socket server writes a grant on send:

```
chatdoc:{documentKey} → { from, to, groupId }   TTL 7 days
```

- **1-on-1** — readable by `from` and `to`
- **Group** — readable by anyone in the group's current `members` list
- **No grant** — treated as "not a chat attachment"; the messaging route 404s

The grant is written server-side from the authenticated socket identity, never
from anything the client supplies. It is also what `corporate-documents/view` and
`/delete` consult (`isForbiddenChatAttachment`) so a chat attachment cannot be
pulled through the generic document routes either.

**Retention is enforced twice**, deliberately: the grant carries a 7-day Redis
TTL so access stops on time even if the reaper is late, and a nightly job at
03:20 deletes the underlying bytes, which no Redis expiry could do.

---

## 5. Gotchas — read before writing any code

**The `base64` field is a data URL, not bare base64.** The web builds it with
`FileReader.readAsDataURL`, producing `data:image/png;base64,AAA…`, and passes
it through verbatim. The app must produce the identical shape:

```dart
final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
```

Send bare base64 and you store bytes that differ from what the web produces for
the same file. Nothing will complain at upload time.

**`description: "BMC-CHAT-ATTACHMENT"` is load-bearing.** It is the only thing
separating a chat attachment from a real corporate document in
`admin_corporateDocuments`, and the nightly reaper matches on it. Omit it and the
file is never deleted — it sits in the document store forever, indistinguishable
from a genuine corporate record. It must stay byte-identical to
`CHAT_ATTACHMENT_MARKER` in `server.ts`.

**The default 15s Dio timeout is too short.** A 5 MB file becomes a ~6.7 MB JSON
body that the app server then relays to an external storage service. On mobile
data this routinely exceeds 15s while nothing is actually wrong.
`AttachmentService` overrides to 90s for upload, 45s for download.

**Error bodies arrive as bytes.** The download route streams raw bytes on success
but returns JSON on failure, so the request must use
`responseType: ResponseType.bytes` and decode error bodies with
`utf8.decode` before the `message` field is readable.

**Upload on send, not on file pick.** A file uploaded but never sent leaves an
orphan row with no grant. Harmless — the reaper clears it in 7 days — but it
wastes storage and shows up in the corporate documents table meanwhile.

**404 is a normal end state.** After 7 days every attachment 404s while its
message stays in the thread. Cache the miss so a thread of expired attachments
does not re-hit the network on every rebuild, and render it as "no longer
available" rather than as a failure.

**"Keep message" does not preserve the file.** `keptBy` protects the message from
deletion; the reaper deletes purely on age and never consults it. A kept message
keeps its text and loses its attachment at 7 days. Do not let the UI imply
otherwise.

**Deleting a message deletes the file for everyone.** The server revokes the
grant and then deletes the stored bytes, so any other participant's copy — kept
or not — stops resolving immediately. `ChatProvider` drops the cached bytes on
`message-deleted` for the same reason.

**Never put attachment bytes in a shared cache.** The response is
`Cache-Control: private` and is scoped to one participant. The in-memory cache in
`AttachmentService` is per-process and is cleared on disconnect/logout so one
user's files cannot survive into the next sign-in.

---

## 6. Changes to the mobile app

### New file

`lib/core/socket/attachment_service.dart` — upload, download, bounded in-memory
cache, single-flight de-duplication, typed failures.

### Changed files

**`socket_models.dart`** — `MessageAttachment.data` → `MessageAttachment.documentKey`,
plus `isValid` / `isImage` helpers and an assert in `ChatMessage.outbound()` that
catches an empty key at the call site rather than letting the server silently
strip the file.

**`chat_provider.dart`** — adds `sendWithAttachment(...)` (uploads, then sends,
and does **not** send if the upload throws), an `isUploading` flag for the
composer, cache eviction on `message-deleted`, and a full cache clear on
disconnect.

### Endpoint constants

```dart
// api_endpoints.dart
static const String uploadDocument      = '/corporate-documents/upload';
static const String messagingAttachment = '/messaging/attachment';
```

Both are relative to the existing `/api` base URL.

### Optional dependency

`image_picker` is already present and covers photos. For arbitrary documents add
`file_picker`. `AttachmentService` takes `Uint8List` + filename + mime type, so
it does not care which picker you use.

---

## 7. Using it

### Sending

```dart
try {
  await context.read<ChatProvider>().sendWithAttachment(
    to: peerUsername,             // groupId when isGroup: true
    content: messageController.text.trim(),
    bytes: pickedBytes,
    fileName: pickedName,
    mimeType: pickedMime,
    onProgress: (sent, total) => setState(() => _progress = sent / total),
  );
  messageController.clear();
} on AttachmentException catch (e) {
  showMessage(e.message);         // keep the draft and the picked file
}
```

### Rendering

```dart
FutureBuilder<Uint8List>(
  future: AttachmentService.instance.download(message.file!),
  builder: (context, snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }
    final error = snap.error;
    if (error is AttachmentException) {
      return AttachmentPlaceholder(
        // 'gone' is expected after 7 days — style it as muted, not as an error.
        muted: error.kind == AttachmentFailure.gone,
        label: error.message,
      );
    }
    if (snap.hasError) return const AttachmentPlaceholder(label: 'Could not load attachment');

    return message.file!.isImage
        ? Image.memory(snap.data!, fit: BoxFit.cover)
        : FileTile(name: message.file!.name, size: message.file!.size, bytes: snap.data!);
  },
)
```

`download()` de-duplicates concurrent calls for the same key, so several widgets
rendering the same attachment produce one request.

---

## 8. Verification

1. **Send an image from the app, open it on web.** Confirms the data-URL format
   matches — if the app sends bare base64 this is where it shows.
2. **Send from web, open on the app.** The reverse path.
3. **Confirm the row is marked.** `SELECT description FROM admin_corporateDocuments
   WHERE id = '<documentKey>'` must return exactly `BMC-CHAT-ATTACHMENT`. If it
   is null, the reaper will never delete that file.
4. **Non-participant fetch.** Sign in as an unrelated user and request the same
   `documentKey` — expect `403`.
5. **Delete the message.** The attachment must 404 for the other party
   immediately, and disappear on this device without a restart.
6. **Expiry.** Temporarily lower `CHAT_ATTACHMENT_RETENTION_DAYS`, or hand-delete
   the `chatdoc:{key}` grant, and confirm the app renders "no longer available"
   rather than an error state.
7. **Large file on mobile data.** A 4–5 MB attachment over 4G — this is what the
   timeout override exists for, and the only way to prove it.
8. **Oversize file.** Confirm the 5 MB cap is refused client-side, before the
   upload starts.
9. **Group attachment.** Send to a group, confirm every member can fetch and a
   non-member gets `403`.

Do all of this against a **release build**. Note that the asserts added in
`ChatMessage.outbound()` are debug-only by design; the runtime guard that matters
in release is `sendWithAttachment` refusing to emit when the upload throws.

---

## 9. Server-side notes

Not required for the mobile work, but worth knowing while testing.

These must be configured or attachments fail in ways that look like client bugs:
`DOC_STORE_UPLOAD_API`, `DOC_STORE_DOWNLOAD_API`, `DOC_STORE_DELETE_API`,
`REDIS_APP_URL`, `REDIS_MSG_STORE_URL`.

The passcode handshake is staged in the **app** Redis store while grants and
message history live in the **message** store — different database indexes on the
same server, and they do not share keys. A route reading the wrong client sees
nothing.

The reaper is gated on `isOnline && isPrimaryWorker` and on `isCronEnabled()`.
If the online deployment is not the one flagged, or cron is disabled, nothing is
ever reaped and attachments accumulate indefinitely — the grants still expire on
schedule, so this presents as "storage grows forever" rather than as a
user-visible bug. Worth a look at the reaper's log line (`Reaped n/m
attachment(s)`) after the first week in production: a run reporting `0/500` means
the external delete call is failing and the same batch is being retried nightly.
