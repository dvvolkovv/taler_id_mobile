import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/dashboard/desktop/widgets/responsive_breakpoints.dart';

void main() {
  test('layoutFor returns expected modes', () {
    expect(ResponsiveBreakpoints.layoutFor(600), DesktopLayout.notSupported);
    expect(ResponsiveBreakpoints.layoutFor(800), DesktopLayout.singlePane);
    expect(ResponsiveBreakpoints.layoutFor(1099), DesktopLayout.singlePane);
    expect(ResponsiveBreakpoints.layoutFor(1100), DesktopLayout.twoPane);
    expect(ResponsiveBreakpoints.layoutFor(1299), DesktopLayout.twoPane);
    expect(ResponsiveBreakpoints.layoutFor(1300), DesktopLayout.threePane);
    expect(ResponsiveBreakpoints.layoutFor(1920), DesktopLayout.threePane);
  });
}
