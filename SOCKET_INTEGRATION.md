# Mobile app → Socket.io integration

Wiring `bmc_staff_self_service_app` into the BMC-Main-App real-time mesh, per
`docs/MOBILE_APP_API.md` and `docs/SOCKET_MESH_AND_HANDSHAKE_AUTH.md`.

**Phase 1 scope:** authenticated connection + presence, 1-on-1 and group
messaging, and live data refresh for the rota/leave/availability screens. Action
notifications are phase 2 — the hooks are marked in the source.

Revision 2 — re-checked against the app repo at `aefb95c` (*"Just edited the
pubspec.yaml file"*, version `1.0.1+2`), which now includes the release-bundling
work. Event names and payload shapes were verified field-by-field against
`server.ts` (socket section ~850–2280) and `types/type.d.ts`.

---

## 0. The one thing that will silently break everything

**On the socket mesh, `userId` means USERNAME.**

`verifyMobileHandshake()` in `server.ts` maps the access-token claims like this:

```ts
sessionId: decoded.sub,       // the uuid
userId:    decoded.username,  // "john.doe"      ← the socket-level identity
username:  decoded.name,      // "John Doe"      ← a display name
```

So:

- the personal room a socket joins is **`{username}`**, not `{uuid}`
- 1-on-1 messages are addressed to the recipient's **username**
- every roster entry's `userId` field is a **username**, and its `username`
  field is a **full name**

But the REST `/api/mobapp/auth/login` response is the opposite way round —
`user.id` is the uuid, `user.username` is the username.

**Use `user.username` for everything socket-related. Use `user.id` only for
REST.** Sending `user.id` as a message `to` produces no error at any layer: the
message is accepted, persisted, and delivered to a room nobody is in.

The web client shares this convention, which is why it has never surfaced as a
bug there — but it is the easiest way to get this integration subtly wrong.

---

## 1. Repo state going in

What landed since the release-build fixes, and what this integration still
assumes.

| Item | State at `aefb95c` |
|---|---|
| `INTERNET` + `ACCESS_NETWORK_STATE` permissions | ✅ in `src/main/AndroidManifest.xml` |
| `applicationId` | ✅ `com.peacehouse.bmc_staff` |
| Release signing via `key.properties` | ✅ wired, `key.properties` correctly gitignored |
| `versionCode` bump discipline | ✅ now `1.0.1+2` |
| ProGuard/R8 | ⚠️ rules added, **minification never enabled** — see §7 |
| `minSdk` | ⚠️ changed from hardcoded `23` to `flutter.minSdkVersion` — see §7 |
| `.env` still bundled as a Flutter asset | ❌ unchanged — `pubspec.yaml:62` |
| `socket_io_client` dependency | ❌ not yet added |
| `lib/core/socket/` | ❌ not yet present |

**A correction to the earlier release-build report.** That report flagged `.env`
as "missing from the project root, so the build will fail". That was read off a
clone. `.env` and `android/key.properties` are both gitignored, so they are
absent from *any* fresh clone by design and are present on the machine that
actually builds. Nothing is broken. The practical consequence for this work is
just that whoever picks it up needs both files handed over out-of-band before
they can build or run anything.

---

## 2. Files to add

Drop these into `lib/core/socket/`:

| File | Role |
|---|---|
| `socket_events.dart` | Event-name constants + the `HR_*` live-refresh keys |
| `socket_models.dart` | `ChatMessage`, `ChatGroup`, `SocketUser`, `PresenceFlags`, … |
| `socket_service.dart` | Connection lifecycle, handshake, token-refresh recovery, typed streams |
| `presence_provider.dart` | Roster + presence (`ChangeNotifier`) |
| `chat_provider.dart` | Conversations, unread, typing, read receipts (`ChangeNotifier`) |
| `live_refresh_registry.dart` | Maps broadcast query keys → provider refresh callbacks |

`SocketService` holds no chat or presence state; the two providers hold no
transport logic. Keep it that way — it is what makes the token-refresh path
testable in isolation.

## 3. pubspec.yaml

```yaml
dependencies:
  socket_io_client: ^3.1.6
```

Version matters. The server runs `socket.io@4.8.1`, and the Dart client's
compatibility table maps `v3.*` → server `v4.7.*`–`v4.*`. `socket_io_client 2.x`
targets servers up to 4.6 and will handshake badly.

Bump `version:` as usual — Play rejects a duplicate `versionCode`, and the
current `1.0.1+2` is already consumed.

## 4. Config — the socket URL is NOT the API base URL

The app still reads config from `.env` via `flutter_dotenv`
(`api_endpoints.dart:1-14`), so this integration follows that pattern rather
than changing it. Add to `.env`:

```env
SOCKET_URL=https://app.yourdomain.com
```

and to `ApiEndpoints`:

```dart
static String get socketUrl {
  final configured = dotenv.env['SOCKET_URL'];
  if (configured != null && configured.isNotEmpty) return configured;
  return SocketService.originFromApiBaseUrl(baseUrl); // strips /api
}
```

Two hard requirements, both from `SOCKET_MESH_AND_HANDSHAKE_AUTH.md §5`:

- **Give it the `https://` URL directly.** `socket.io-client` does not follow
  the 301 in the nginx HTTP vhost. The failure it produces looks like a CORS or
  firewall problem and is neither.
- **Point at the online deployment** (`MASTER_APP_URL`). Both deployments share
  one mesh via the Redis adapter, so either reaches every user — but the mobile
  surface is internet-facing and should not depend on the LAN deployment being
  reachable.

`SocketService.configure()` **throws** on both mistakes. Deliberately a throw and
not an `assert` — see §7.

## 5. Wiring in `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // MUST precede configure()
  BMCRouter();
  await dotenv.load(fileName: '.env');

  SocketService.instance.configure(
    socketUrl: ApiEndpoints.socketUrl,
    readAccessToken: SecureStorage.instance.getAccessToken,
    // ⚠️ Must be the SAME single-flight refresh the Dio AuthInterceptor uses.
    refreshAccessToken: AuthRefresh.instance.getFreshAccessToken,
    onAuthLost: () => BMCRouter.router.go('/login'),
    privileges: () => _userProvider.user?.privileges ?? const [],
    dnd: () => _userProvider.user?.doNotDisturb ?? false,
  );

  runApp(const BMCStaffSelfService());
}
```

Then register the providers alongside the existing ones:

```dart
ChangeNotifierProvider(create: (_) => PresenceProvider()),
ChangeNotifierProvider(create: (_) => ChatProvider()),
Provider(create: (_) => LiveRefreshRegistry(), dispose: (_, r) => r.dispose()),
```

### The refresh path must be shared, not duplicated

`MOBILE_APP_API.md` is explicit that refresh tokens are **single-use with
rotation, and reuse revokes the whole family**. If the socket runs its own
refresh while a Dio 401 runs another, the second presents an already-rotated
token, the server reads that as theft, and the user is logged out of that
device entirely.

Extract the interceptor's single-flight refresh into something both can call:

```dart
class AuthRefresh {
  AuthRefresh._();
  static final instance = AuthRefresh._();

  Future<String?>? _inFlight;

  Future<String?> getFreshAccessToken() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<String?> _run() async { /* POST /mobapp/auth/refresh, persist BOTH tokens */ }
}
```

## 6. Connect and disconnect on the auth boundary

In `AuthProvider.login()`, after `userProvider.setUserFromLogin(response.user)`:

```dart
// USERNAME, not user.id — see §0.
context.read<PresenceProvider>().me = response.user.username;
context.read<ChatProvider>().me    = response.user.username;
await SocketService.instance.connect();
```

In `AuthProvider.logout()`, **before** clearing storage:

```dart
await SocketService.instance.disconnect(); // emits process-user-sign-out
```

That emit is what clears this surface's presence flag and leaves the rooms. Just
dropping the transport also works — the server's `disconnect` handler recomputes
presence — but the explicit sign-out is immediate and does not depend on a clean
close, which phones rarely give you.

`AuthProvider.checkAuthStatus()` is the warm-start path: it already calls
`userProvider.fetchMe()` when a stored token is found. Connect there too, after
`_state = AuthState.success`.

---

## 7. Release build & bundling — what the recent changes mean here

This section is the reason for revision 2. The bundling work changed the release
build in three ways that touch this integration.

### Minification is configured but not switched on

`android/app/build.gradle.kts` sets `proguardFiles(...)` on the release build
type but never sets `isMinifyEnabled`. AGP defaults it to `false`, so **R8
shrinking and obfuscation do not run, and `proguard-rules.pro` is inert.**

Two consequences, in order of importance:

1. **Good for now.** Nothing in the socket layer can be stripped, so this
   integration needs no keep rules today. `socket_io_client` is pure Dart —
   Dart code is compiled by the Dart AOT compiler and is not visible to R8 at
   all — so even with minification on, the client itself is not at risk.
2. **A trap for later.** The rules read as tested and are not. The day someone
   sets `isMinifyEnabled = true` to shrink the AAB, R8 runs for the first time
   against the full dependency set, and `-keep class com.peacehouse.bmc_staff.**`
   covers exactly one Kotlin file (`MainActivity`). The `-dontwarn
   com.google.android.play.core.**` entries are the standard fix for an R8 error
   that only appears once minification is enabled — which suggests these rules
   were written against a config that had it on at some point.

If shrinking is wanted, enable it deliberately and re-run the §8 checklist
against that build:

```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    signingConfig = signingConfigs.getByName("release")
    proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
}
```

If it is not wanted, delete `proguard-rules.pro` and the `proguardFiles` line
rather than leaving dead configuration that implies coverage it does not have.

### `assert` does not exist in release builds

Dart strips `assert` in release mode. Any config validation written as an assert
fails loudly in debug and **silently in the Play Store build** — which is the
precise shape of the bug this app already shipped once.

`SocketService.configure()` therefore **throws** `ArgumentError` for a bad socket
URL rather than asserting. Both checks are deterministic (they depend on build
config, not runtime data), so a throw fires on the first launch of any build,
including internal testing, and cannot reach a user.

The remaining asserts in the socket layer — e.g. `ChatMessage.outbound()`
requiring a `groupId` when `isGroup` is true — guard *programmer* errors at call
sites that are exercised by any smoke test, so debug-only is appropriate there.
Anything new that validates **configuration** should be a throw, not an assert.

### `minSdk` moved off its pinned value

`defaultConfig.minSdk` changed from a hardcoded `23` to `flutter.minSdkVersion`.
Worth confirming what that resolves to on your Flutter version, because
`flutter_secure_storage: ^10.2.0` needs **API 23+** for the
`EncryptedSharedPreferences` backend — and secure storage is where the access
token that authenticates the socket handshake lives. If the resolved value is
below 23, the failure is at the token layer, and the socket will simply look
like it cannot authenticate.

```bash
./gradlew :app:properties | grep -i minSdk
```

Pin it back to `23` if it resolved lower.

---

## 8. Using it

### Presence badge

```dart
final presence = context.watch<PresenceProvider>();
final reachable = presence.isReachable(user.username);
final phoneOnly = presence.isOnPhoneOnly(user.username);
```

Use `isReachable`, never `online || local`. A user whose only session is their
phone reads `{online:false, local:false, mobile:true}` — the backend docs call
out `!online && !local` as the exact check that renders them incorrectly as
offline.

### Chat

```dart
final chat = context.read<ChatProvider>();
chat.openConversation(peerUsername);
chat.send(to: peerUsername, content: text);
chat.send(to: groupId, content: text, isGroup: true);
chat.notifyTyping(peerUsername);            // debounced, one start + one stop
```

`chat.totalUnread` drives the existing message badge.

### Live data refresh

Register in a screen's `initState`, dispose the returned disposer:

```dart
late final VoidCallback _off;

@override
void initState() {
  super.initState();
  _off = context.read<LiveRefreshRegistry>().register(
    [LiveRefreshKeys.myShifts, LiveRefreshKeys.rotaPeriod, LiveRefreshKeys.swap],
    () => context.read<RotaProvider>().refreshShiftsForMonth(...),
  );
}

@override
void dispose() { _off(); super.dispose(); }
```

Key names verified against the web app's own definitions:

| Screen | Keys (`lib/query-hooks/hr-hooks/`) |
|---|---|
| Rota | `HR_MY_SHIFTS`, `HR_ROTA_PERIOD`, `HR_SWAP` (`rota-hooks.ts:26-29`) |
| Leave | `HR_LEAVE_REQUESTS`, `HR_MY_LEAVE` (`leave-hooks.ts:16-17`) |
| Availability | `HR_AVAILABILITY`, `HR_AVAILABILITY_WINDOW` (`availability-hooks.ts:14-15`) |
| Personnel | `HR_PERSONNEL` (`personnel-hooks.ts:9`) |

The server is a pure passthrough here — `socket.to(target).emit(...)` — so a
mistyped key is a silent no-refresh, never an error. If a screen stops
refreshing after a backend change, check these strings first.

When the **app itself** mutates HR data, mirror the web app and tell everyone
else:

```dart
SocketService.instance.broadcastInvalidation([LiveRefreshKeys.swap]);
```

`socket.to(target)` excludes the sender, so this never round-trips back — refresh
local state directly as well.

---

## 9. Server behaviours the client has to absorb

All verified in `server.ts`, all handled in the code — listed so nobody
"simplifies" the handling away later.

**Rooms are joined on sign-in, not at handshake.** `process-user-sign-in` is
where the server joins the personal room, `global-users`, `mobile-users`,
privilege rooms and group rooms (`server.ts:1184-1225`). Connect without emitting
it and the socket is connected but deaf. `SocketService` emits it in `onConnect`.

**The group roster needs an explicit request.** Sign-in joins `group:*` rooms
but never sends the group list — only `process-request-groups-list` does
(`server.ts:2011-2023`). `SocketService` emits it right after sign-in; without it
group chats and their history never appear.

**Senders receive their own group messages twice.** The server emits to the
group room — which the sender is in — *and* does a direct `socket.emit` back
(`server.ts:1455-1458`). `ChatProvider` dedupes on the server-minted message id.
Do not remove `_seenIds`.

**`toggle` on keep-message is not the desired state.** The server reads it as
"this is a toggle request" and picks the direction itself
(`server.ts:1688-1695`). Sending `false` to un-keep matches neither branch, yet
still emits `message-kept` — leaving the UI stuck forever. Always send `true`.

**Group typing needs the `group:` prefix.** The typing handler fans out with a
bare `socket.to(to)` and ignores the `groupId` field (`server.ts:1720-1731`),
but group rooms are named `group:{id}`. `SocketService` adds the prefix.

**The roster includes you.** `send-users-list` iterates every session
(`server.ts:1145-1159`). `PresenceProvider.allUsers` filters on `me`, so set it
before connecting.

**Offline backlog arrives with the roster.** Each `send-users-list` entry carries
the message history with that user, so there is no separate history fetch —
seeding from the roster *is* the backlog.

**Your other devices do not see your own 1-on-1 messages live.** The server
echoes to the emitting socket only, not to the sender's personal room
(`server.ts:1467-1468`). Phone and web open at once: a message sent on the phone
does not appear on the web tab until it re-signs-in. Server behaviour, not a
client gap — worth a backend ticket if it matters. (Group messages are fine.)

**Attachments travel inline as base64** over the socket, and every byte crosses
the Redis adapter to every node. Cap the size client-side; this is not an upload
endpoint.

**Privileges are frozen at token-mint time.** Room membership comes from the
token's claims, so a privilege change only reaches the app on the next refresh
or a logout/login. If a user says "I was granted access but the app still blocks
me", the answer is log out and back in.

---

## 10. Verification checklist

Nothing below can be proved from source alone — the backend's own doc lists "a
real mobile client" as **not yet verified**, so this integration is the first
real exercise of the mobile handshake path. Expect to find something.

**Run the whole list against a release build, not just debug.** The bug that
started this thread existed only in release, and `flutter run --release` on a
USB phone reproduces that class of problem in about a minute. Debug-only testing
cannot see it.

1. **Handshake** — log in, confirm the server logs `✅ User signed-in:` with the
   username. A rejection logs `⛔ Mobile socket rejected`.
2. **`surface`** — from a web session, confirm the user reads
   `{online:false, local:false, mobile:true}`.
3. **Two surfaces** — sign in on web and phone; confirm `online` and `mobile` are
   both true, then sign out of the phone and confirm `online` stays true. This is
   the exact case the old flag-mutation logic could not represent.
4. **DM both ways** — phone → web and web → phone, addressed by username.
5. **Group** — confirm the sender sees exactly one copy of their own message.
6. **Token expiry** — hand-mint a token with `expiresIn: '10s'`, connect, wait.
   The socket must refresh and reconnect, not log the user out. This path is the
   most likely to bite in production and the least likely to be exercised by
   hand.
7. **Live refresh** — change a rota shift in the web app; the phone's rota screen
   should refetch within ~400 ms (the registry's coalescing window).
8. **Airplane mode** — toggle for 30 s; confirm reconnect and that presence is
   not stuck "on" for other users.
9. **Bad socket URL** — temporarily set `SOCKET_URL` to the `/api` base URL and
   confirm the app throws at startup **in a release build**. This proves the
   config guard survives the release compile.

## 11. Not in this drop

- **Action notifications** (`send-action-notification`,
  `send-cancel-action-notification`, `send-plain-notification`) — the constants
  exist, no listeners are registered. This is what feeds the existing
  notification badge, and it is a small addition: a fourth provider subscribing
  to three more streams.
- **Push when the app is killed.** Sockets only deliver to a running app. Real
  push needs FCM; `mobile-users` exists as a room specifically so the server can
  fan out push-style payloads to mobile clients on its own.
- **Reconnect-time roster resync.** On resume the client reconnects and re-signs
  in, which re-seeds the roster. Long backgrounding is covered; a same-second
  reconnect could in principle miss a message sent during the gap.
- **Moving secrets out of the bundled `.env`.** Still outstanding from the
  release-build report: `.env` ships inside the APK as a Flutter asset, so
  `MOBILE_API_KEY` is recoverable with `unzip`. Unchanged by this work, and
  unchanged by the bundling commits.
