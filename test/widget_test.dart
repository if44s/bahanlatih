import 'package:flutter_test/flutter_test.dart';

import 'package:praktek_mobile_gis/main.dart';

void main() {
  testWidgets('App shows bottom navigation with 3 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileGISApp());
    await tester.pump();

    expect(find.text('Peta'), findsOneWidget);
    expect(find.text('Survei'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
