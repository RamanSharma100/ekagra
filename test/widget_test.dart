import 'package:flutter_test/flutter_test.dart';
import 'package:ekagra/app/app.dart';

void main() {
  testWidgets('EkagraApp loads home view and renders focus score', (WidgetTester tester) async {
    await tester.pumpWidget(const EkagraApp());
    await tester.pumpAndSettle();

    expect(find.text("Today's Focus Score"), findsOneWidget);
    expect(find.text("Start Focus"), findsOneWidget);
  });
}
