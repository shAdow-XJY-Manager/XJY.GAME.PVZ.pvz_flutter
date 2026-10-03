import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_pvz/main.dart';
import 'package:shadow_pvz/lane_defense.dart';
import 'package:shadow_pvz/frequency/game_support.dart';

Finder cells() => find.descendant(
  of: find.byType(KeyboardBoard),
  matching: find.byType(OutlinedButton),
);

void main() {
  setUp(() {
    saveMap('pvz.save', {});
    saveMap('results', {});
  });
  testWidgets(
    'Ready does not advance ticker simulation; start enables planting and pause freezes it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.text('电路守线'), findsOneWidget);
      expect(find.text('开始守线'), findsOneWidget);
      expect(cells(), findsNWidgets(18));
      expect(
        tester
            .widgetList<OutlinedButton>(cells())
            .every((b) => b.onPressed == null),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(readMap('pvz.save'), isEmpty);
      expect(find.text('准备中'), findsOneWidget);
      expect(find.text('0 秒'), findsOneWidget);
      await tester.tap(find.text('开始守线'));
      await tester.pump();
      expect(find.text('开始守线'), findsNothing);
      await tester.tap(cells().first);
      await tester.pump();
      final game = LaneDefense.fromJson(
        objectMap(readMap('pvz.save')!['game']),
      )!;
      expect(game.units.single.type, 1);
      expect(game.units.single.row, 0);
      expect(game.units.single.col, 0);
      expect(game.energy, 25);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.tap(find.byTooltip('暂停'));
      await tester.pump();
      final paused = objectMap(readMap('pvz.save')!['game']);
      expect(paused['time'] as num, greaterThan(0));
      await tester.pump(const Duration(seconds: 2));
      expect(objectMap(readMap('pvz.save')!['game']), paused);
      expect(find.text('已暂停'), findsOneWidget);
      expect(localRecords(), isEmpty);
    },
  );
}
