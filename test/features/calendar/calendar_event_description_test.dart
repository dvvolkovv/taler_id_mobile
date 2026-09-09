import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/calendar/presentation/screens/calendar_event_description.dart';

String _locationPrefix(String location) => 'Место: $location';

void main() {
  group('roomCodeFromLink', () {
    test('extracts the code from a prod-domain room link', () {
      expect(roomCodeFromLink('https://id.taler.tirol/room/abc-123'), 'abc-123');
    });

    test('extracts the code from a staging-domain room link', () {
      expect(roomCodeFromLink('https://staging.id.taler.tirol/room/xyz'), 'xyz');
    });

    test('returns null when there is no /room/ segment', () {
      expect(roomCodeFromLink('https://id.taler.tirol/oauth/auth'), isNull);
    });

    test('ignores a trailing slash after the code', () {
      // The regex's [\w-]+ doesn't consume '/', so a stray trailing slash
      // (or anything else non-word after the code) doesn't change the
      // extracted code — this is exactly what makes comparing by code
      // robust where comparing full strings was not.
      expect(roomCodeFromLink('https://id.taler.tirol/room/abc-123/'), 'abc-123');
    });

    test('handles codes containing digits and hyphens', () {
      expect(roomCodeFromLink('https://id.taler.tirol/room/9f2-ab-01'), '9f2-ab-01');
    });
  });

  group('passwordAppliesToLocation', () {
    const link = 'https://id.taler.tirol/room/abc-123';

    test('false when there is no password', () {
      expect(
        passwordAppliesToLocation(location: link, meetingLink: link, meetingPassword: null),
        isFalse,
      );
    });

    test('false when the password is an empty string', () {
      expect(
        passwordAppliesToLocation(location: link, meetingLink: link, meetingPassword: ''),
        isFalse,
      );
    });

    test('false when there is no meeting link on record', () {
      expect(
        passwordAppliesToLocation(location: link, meetingLink: null, meetingPassword: 'secret'),
        isFalse,
      );
    });

    test('true when location matches the meeting link exactly', () {
      expect(
        passwordAppliesToLocation(location: link, meetingLink: link, meetingPassword: 'secret'),
        isTrue,
      );
    });

    test('true when location differs only by a trailing slash (regression: was full-string compare)', () {
      expect(
        passwordAppliesToLocation(location: '$link/', meetingLink: link, meetingPassword: 'secret'),
        isTrue,
      );
    });

    test('false when location points at a different room code', () {
      expect(
        passwordAppliesToLocation(
          location: 'https://id.taler.tirol/room/different-code',
          meetingLink: link,
          meetingPassword: 'secret',
        ),
        isFalse,
      );
    });

    test('false when location is not a room link at all', () {
      expect(
        passwordAppliesToLocation(location: 'Office, 3rd floor', meetingLink: link, meetingPassword: 'secret'),
        isFalse,
      );
    });
  });

  group('buildEventDescription', () {
    const link = 'https://id.taler.tirol/room/abc-123';

    test('empty location returns the user description unchanged', () {
      final result = buildEventDescription(
        userDescription: 'Quarterly sync',
        location: '',
        isRoomLink: false,
        meetingLink: null,
        meetingPassword: null,
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, 'Quarterly sync');
    });

    test('non-link location is wrapped by locationPrefixBuilder, no password line', () {
      final result = buildEventDescription(
        userDescription: 'Quarterly sync',
        location: 'Office, 3rd floor',
        isRoomLink: false,
        meetingLink: null,
        meetingPassword: 'secret',
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, 'Quarterly sync\nМесто: Office, 3rd floor');
    });

    test('room link with no password appends only the link', () {
      final result = buildEventDescription(
        userDescription: 'Quarterly sync',
        location: link,
        isRoomLink: true,
        meetingLink: link,
        meetingPassword: null,
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, 'Quarterly sync\n$link');
    });

    test('room link with a matching password appends link then password, each its own line', () {
      final result = buildEventDescription(
        userDescription: 'Quarterly sync',
        location: link,
        isRoomLink: true,
        meetingLink: link,
        meetingPassword: 'secret',
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, 'Quarterly sync\n$link\nPassword: secret');
    });

    test('password is never appended inside the link line itself', () {
      final result = buildEventDescription(
        userDescription: '',
        location: link,
        isRoomLink: true,
        meetingLink: link,
        meetingPassword: 'secret',
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      final lines = result.split('\n');
      expect(lines, [link, 'Password: secret']);
      expect(lines[0], isNot(contains('secret')));
    });

    test('a trailing slash on the location still carries the password (regression)', () {
      final result = buildEventDescription(
        userDescription: '',
        location: '$link/',
        isRoomLink: true,
        meetingLink: link,
        meetingPassword: 'secret',
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, '$link/\nPassword: secret');
    });

    test('editing the location to a different room drops the password silently but safely', () {
      const editedLink = 'https://id.taler.tirol/room/different-code';
      final result = buildEventDescription(
        userDescription: '',
        location: editedLink,
        isRoomLink: true,
        meetingLink: link,
        meetingPassword: 'secret',
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, editedLink);
      expect(result, isNot(contains('secret')));
    });

    test('empty user description does not leave a leading blank line', () {
      final result = buildEventDescription(
        userDescription: '',
        location: link,
        isRoomLink: true,
        meetingLink: link,
        meetingPassword: null,
        passwordLabel: 'Password',
        locationPrefixBuilder: _locationPrefix,
      );
      expect(result, link);
    });
  });
}
