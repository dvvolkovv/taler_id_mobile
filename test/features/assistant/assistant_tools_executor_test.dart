import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/assistant/tools/assistant_tools_executor.dart';

void main() {
  test('unknown tool returns readable message', () async {
    final ex = AssistantToolsExecutor();
    expect(await ex.execute('no_such_tool', {}), contains('Unknown tool'));
  });

  test('session-bound tool without hooks refuses politely', () async {
    final ex = AssistantToolsExecutor();
    final res = await ex.execute('end_session', {});
    expect(res.toLowerCase(), contains('voice session'));
  });
}
