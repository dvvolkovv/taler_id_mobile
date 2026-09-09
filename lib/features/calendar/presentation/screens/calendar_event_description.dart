/// Extracts the room code from a Taler ID meeting link
/// (e.g. `https://id.taler.tirol/room/abc-123` → `abc-123`), or null if
/// [url] has no `/room/<code>` segment.
///
/// Used to decide whether a location field still points at the room a
/// password was generated for. Comparing by code (rather than the full
/// URL string) means an incidental trailing slash or stray character
/// typed into the field doesn't make a still-valid password look like it
/// belongs to a different room.
String? roomCodeFromLink(String url) {
  final match = RegExp(r'/room/([\w-]+)').firstMatch(url);
  return match?.group(1);
}

/// True when [meetingPassword] is set and [location] still points at the
/// same room as [meetingLink] — compared by room code via
/// [roomCodeFromLink], not full-string equality.
///
/// Single source of truth for "does the generated password still apply",
/// shared by the live form's password preview row and
/// [buildEventDescription]'s save-time decision, so the two can't drift
/// out of sync with each other.
bool passwordAppliesToLocation({
  required String location,
  required String? meetingLink,
  required String? meetingPassword,
}) {
  if (meetingPassword == null || meetingPassword.isEmpty) return false;
  if (meetingLink == null) return false;
  final locationCode = roomCodeFromLink(location);
  if (locationCode == null) return false;
  return locationCode == roomCodeFromLink(meetingLink);
}

/// Builds the text saved as a calendar event's description, mirroring
/// what `_EventEditScreenState._save()` sends to the server.
///
/// - If [location] is empty, [userDescription] is returned unchanged.
/// - If [isRoomLink] is true, [location] is appended as its own line
///   verbatim (the caller has already classified it as one of our room
///   links — this function doesn't re-derive that).
/// - Otherwise, [location] is appended wrapped by
///   [locationPrefixBuilder] (e.g. "Место: `location`").
/// - The room password is appended as its own line, separate from the
///   link, only when [passwordAppliesToLocation] holds. The password is
///   never written inside the link itself.
String buildEventDescription({
  required String userDescription,
  required String location,
  required bool isRoomLink,
  required String? meetingLink,
  required String? meetingPassword,
  required String passwordLabel,
  required String Function(String location) locationPrefixBuilder,
}) {
  if (location.isEmpty) return userDescription;

  if (isRoomLink) {
    var description = userDescription.isNotEmpty ? '$userDescription\n$location' : location;
    if (passwordAppliesToLocation(
      location: location,
      meetingLink: meetingLink,
      meetingPassword: meetingPassword,
    )) {
      description = '$description\n$passwordLabel: $meetingPassword';
    }
    return description;
  }

  final locPrefix = locationPrefixBuilder(location);
  return userDescription.isNotEmpty ? '$userDescription\n$locPrefix' : locPrefix;
}
