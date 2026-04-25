import 'package:flutter_test/flutter_test.dart';

import 'package:taler_id_mobile/core/config/mesh_config.dart';

void main() {
  group('MeshConfig', () {
    test('bleEnabled default is false', () {
      expect(MeshConfig.bleEnabled, isFalse);
    });
  });
}
