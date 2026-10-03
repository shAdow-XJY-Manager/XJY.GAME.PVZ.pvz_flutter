import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_pvz/main.dart';
import 'package:shadow_pvz/frequency/game_support.dart';

Future<void> withLargeText(
  WidgetTester tester,
  Future<void> Function() checks,
) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  try {
    await tester.pumpWidget(Builder(builder: (context) {
      final app = const MyApp().build(context) as MaterialApp;
      return MaterialApp(
        title: app.title,
        theme: app.theme,
        darkTheme: app.darkTheme,
        themeMode: app.themeMode,
        home: app.home,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
      );
    }));
    await tester.pump(const Duration(milliseconds: 100));
    await checks();
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void expectScaledText(WidgetTester tester, String label) {
  final text = find.text(label);
  expect(text, findsOneWidget);
  expect(MediaQuery.textScalerOf(tester.element(text)).scale(14), 28);
  final rich = find.descendant(of: text, matching: find.byType(RichText));
  expect(rich, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(rich);
  expect(paragraph.textScaler.scale(14), 28);
  expect(paragraph.didExceedMaxLines, isFalse, reason: '$label must be complete');
  expect(
    paragraph.getMaxIntrinsicHeight(paragraph.size.width),
    lessThanOrEqualTo(paragraph.size.height + 1),
    reason: '$label must not be clipped vertically',
  );
}

Finder button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

Future<void> tapVisible(WidgetTester tester, Finder control) async {
  await tester.ensureVisible(control);
  await tester.pump(const Duration(milliseconds: 100));
  expect(control.hitTestable(), findsOneWidget);
  final rect = tester.getRect(control);
  expect(rect.left, greaterThanOrEqualTo(-1));
  expect(rect.right, lessThanOrEqualTo(321));
  expect(rect.top, greaterThanOrEqualTo(-1));
  expect(rect.bottom, lessThanOrEqualTo(801));
  expect(MediaQuery.textScalerOf(tester.element(control)).scale(14), 28);
  await tester.tap(control.hitTestable());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('320px at real 200% text keeps defense ready, facility choice, planting and pause usable',
      (tester) async {
    saveMap('pvz.save', {});
    saveMap('results', {});
    await withLargeText(tester, () async {

      expectScaledText(tester, '开始守线');
      expect(readMap('pvz.save'), isEmpty);
      await tapVisible(tester, button('开始守线'));
      expectScaledText(tester, '能源站 50');
      await tapVisible(tester, find.widgetWithText(ChoiceChip, '能源站 50'));
      final firstCell = find.descendant(
        of: find.byType(KeyboardBoard),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      ).first;
      await tapVisible(tester, firstCell);
      final game = objectMap(readMap('pvz.save')!['game']);
      expect(game['units'], hasLength(1));
      expect((game['units'] as List).single['type'], 0);

      await tapVisible(tester, find.byTooltip('暂停'));
      expectScaledText(tester, '继续游戏');
      expect(find.text('已暂停'), findsOneWidget);
      await tapVisible(tester, button('继续游戏'));
      expect(find.text('已暂停'), findsNothing);
    });
  });
}
