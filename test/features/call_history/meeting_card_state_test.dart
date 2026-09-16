import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/call_history/presentation/screens/call_history_screen.dart';

/// A recording that captured no audio leaves a row on purpose — that is how the
/// user learns it failed instead of wondering where the meeting went. The card
/// used to render it like any other meeting, with the failure text sitting in
/// the summary slot where a recap belongs.
///
/// Only the classification is pinned here, not the layout: what regresses is a
/// new backend status quietly falling into the wrong bucket.
void main() {
  group('meetingCardState', () {
    test('a finished recap is ready', () {
      expect(meetingCardState('done'), MeetingCardState.ready);
    });

    test('a recap still being built is processing', () {
      expect(meetingCardState('processing'), MeetingCardState.processing);
    });

    test('both failure statuses read as failed', () {
      expect(meetingCardState('failed_no_audio'), MeetingCardState.failed);
      expect(meetingCardState('failed'), MeetingCardState.failed);
    });

    test('an unknown or missing status is treated as a normal meeting', () {
      // Legacy rows predate the status column; a status we do not recognise is
      // not a reason to accuse the recording of having failed.
      expect(meetingCardState(null), MeetingCardState.ready);
      expect(meetingCardState(''), MeetingCardState.ready);
      expect(meetingCardState('something_new'), MeetingCardState.ready);
    });
  });
}
