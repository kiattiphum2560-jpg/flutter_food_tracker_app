import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_food_tracker_app/main.dart';

void main() {
  testWidgets('shows the food tracker dashboard', (tester) async {
    await tester.pumpWidget(const FoodTrackerApp());

    expect(find.text('วันนี้กินอะไรดี?'), findsOneWidget);
    expect(find.text('ข้าวโอ๊ตกับกล้วย'), findsOneWidget);
    expect(find.text('960 จากเป้าหมาย 2000 กิโลแคลอรี'), findsOneWidget);
  });

  testWidgets('adds a food entry and updates calories', (tester) async {
    await tester.pumpWidget(const FoodTrackerApp());

    await tester.tap(find.byKey(const ValueKey('add-food-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'สลัดอกไก่');
    await tester.enterText(find.byType(TextFormField).at(1), '250');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('สลัดอกไก่'), findsOneWidget);
    expect(find.text('1210 จากเป้าหมาย 2000 กิโลแคลอรี'), findsOneWidget);
  });

  testWidgets('does not save an entry with invalid calories', (tester) async {
    await tester.pumpWidget(const FoodTrackerApp());

    await tester.tap(find.byKey(const ValueKey('add-food-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'สลัดอกไก่');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกจำนวนแคลอรีที่ถูกต้อง'), findsOneWidget);
    expect(find.text('สลัดอกไก่'), findsNothing);
  });
}
