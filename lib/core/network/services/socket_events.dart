// socket_events.dart
//
// Event-name constants for the BMC-Main-App Socket.io mesh.
//
// These strings are a WIRE CONTRACT with `server.ts` on the backend. They are
// mirrored from `types/type.d.ts` (`ClientToServerEvents` /
// `ServerToClientEvents`). Do not rename anything here without changing the
// server — a typo is a silent no-op, not a compile error.

class SocketEvents {
  SocketEvents._();

  // ── Client → Server ───────────────────────────────────────────────────────

  /// MUST be emitted after every successful connect. The server joins the
  /// personal room, `global-users`, `mobile-users`, privilege rooms and group
  /// rooms inside THIS handler — not at handshake. Skip it and the socket is
  /// connected but in no rooms, so it receives nothing.
  ///
  /// Takes a privileges array for wire compatibility with the web client; the
  /// server ignores it and uses the privileges in the verified access token.
  static const userSignIn = 'process-user-sign-in';

  /// Leaves all rooms and clears this surface's presence flag. Emit on logout
  /// BEFORE disconnecting.
  static const userSignOut = 'process-user-sign-out';

  static const requestUsersList = 'process-request-users-list';

  /// Phase 2. The server answers this only with `send-action-notification`,
  /// which nothing here listens for yet — SocketService deliberately does not
  /// expose an emitter for it.
  static const requestBacklog = 'process-request-backlog';

  static const sendMessage = 'process-send-message';
  static const markMessagesRead = 'process-mark-messages-read';
  static const deleteMessage = 'process-delete-message';
  static const keepMessage = 'process-keep-message';
  static const typingStart = 'process-typing-start';
  static const typingStop = 'process-typing-stop';

  static const invalidateQueries = 'process-invalidate-queries';

  static const requestGroupsList = 'process-request-groups-list';
  static const createGroup = 'process-create-group';
  static const addGroupMember = 'process-add-group-member';
  static const removeGroupMember = 'process-remove-group-member';
  static const updateGroup = 'process-update-group';
  static const deleteGroup = 'process-delete-group';
  static const promoteAdmin = 'process-promote-admin';
  static const demoteAdmin = 'process-demote-admin';

  // ── Server → Client ───────────────────────────────────────────────────────

  /// Full roster, sent once in response to [userSignIn]. Each entry also
  /// carries the message history between that user and us — this is the
  /// offline backlog, so there is no separate "fetch history" call.
  static const usersList = 'send-users-list';
  static const requestedUsersList = 'send-requested-users-list';

  static const userSignedIn = 'send-user-sign-in';
  static const userSignedOut = 'send-user-sign-out';
  static const userDisconnected = 'send-user-disconnected';

  static const receiveMessage = 'receive-message';
  static const messagesMarkedRead = 'send-messages-marked-read';
  static const groupMessagesMarkedRead = 'send-group-messages-marked-read';
  static const messageDeleted = 'message-deleted';
  static const messageKept = 'message-kept';
  static const userTyping = 'user-typing';
  static const userStoppedTyping = 'user-stopped-typing';

  /// `{ queryKeys: string[][] }` — another client mutated server state.
  static const invalidateQueriesIn = 'send-invalidate-queries';

  static const groupsList = 'send-groups-list';
  static const groupCreated = 'group-created';
  static const groupUpdated = 'group-updated';
  static const groupDeleted = 'group-deleted';
  static const groupMemberAdded = 'group-member-added';
  static const groupMemberRemoved = 'group-member-removed';
  static const groupAdminPromoted = 'group-admin-promoted';
  static const groupAdminDemoted = 'group-admin-demoted';
}

/// Query-key strings the backend broadcasts, taken from
/// `lib/query-hooks/hr-hooks/*.ts`. Only the ones this app renders are listed.
///
/// The web app uses these as TanStack Query keys; here they are just opaque
/// identifiers we map to provider refresh callbacks.
class LiveRefreshKeys {
  LiveRefreshKeys._();

  static const myShifts = 'HR_MY_SHIFTS';
  static const rotaPeriod = 'HR_ROTA_PERIOD';
  static const swap = 'HR_SWAP';

  static const leaveRequests = 'HR_LEAVE_REQUESTS';
  static const myLeave = 'HR_MY_LEAVE';

  static const availability = 'HR_AVAILABILITY';
  static const availabilityWindow = 'HR_AVAILABILITY_WINDOW';

  static const personnel = 'HR_PERSONNEL';

  // ── Clinic desk / telemedicine visit lists ───────────────────────────────
  //
  // Broadcast by the web app (and by the server itself) whenever a row in
  // `clinic_patientVisits` changes in a way the visit lists render:
  //   • the clinic desk calls the patient in            (clinicals/[sectId]/[sectName])
  //   • triage is completed, or bypassed                (same screen)
  //   • the consultant toggles ready                    (my-clinics / this app)
  //
  // Which of the three keys arrives depends on which web screen the change was
  // made from, so treat them as one signal — see [telemedVisits].
  static const bookingVisits = 'BOOKING-VISITS';
  static const providersBookingVisits = 'PROVIDERS-BOOKING-VISITS';
  static const guestsBookingVisits = 'GUESTS-BOOKING-VISITS';

  /// Any one of these means "the telemedicine visit lists may be stale".
  static const telemedVisits = <String>{
    bookingVisits,
    providersBookingVisits,
    guestsBookingVisits,
  };
}
