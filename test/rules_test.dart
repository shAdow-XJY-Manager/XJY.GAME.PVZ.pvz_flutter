import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_pvz/lane_defense.dart';

void advance(LaneDefense game, int frames) {
  for (var i = 0; i < frames; i++) {
    game.tick(1 / 60);
  }
}

Map<String, dynamic> snapshot(LaneDefense game) =>
    jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;

void main() {
  test('planting enforces bounds, costs, cooldown and occupied cells', () {
    final game = LaneDefense();
    for (final args in [
      [-1, 0, 0],
      [3, 0, 0],
      [0, 5, 0],
      [0, 0, 3],
    ]) {
      expect(game.plant(args[0], args[1], args[2]), isFalse);
    }
    expect(game.energy, 100);
    expect(game.plant(0, 0, 0), isTrue);
    expect(game.energy, 50);
    expect(game.plant(0, 1, 0), isFalse);
    expect(game.plant(0, 0, 2), isFalse);
    expect(game.plant(1, 0, 1), isFalse);
    advance(game, 301);
    expect(game.plant(0, 1, 0), isTrue);
    expect(game.energy, 0);
    expect(game.remove(0, 0), isTrue);
    expect(game.remove(0, 0), isFalse);
    expect(game.energy, 0, reason: 'removal never refunds energy');
  });

  test(
    'energy station and sky drops collect once; expired drops give nothing',
    () {
      final game = LaneDefense()..plant(0, 0, 0);
      advance(game, 481);
      expect(game.drops, hasLength(1));
      expect(game.collect(), 25);
      expect(game.energy, 75);
      expect(game.collect(), 0);
      advance(game, 120);
      expect(game.collect(), 25);
      game.drops.add(EnergyDrop(-1, -1, game.time));
      game.drops.add(EnergyDrop(1, 1, game.time + 1));
      expect(game.collect(), 25);
      expect(game.drops, isEmpty);
    },
  );

  test(
    'fixed-step projectiles damage and remove a target in their own lane',
    () {
      final game = LaneDefense()..plant(0, 0, 1);
      game.enemies.add(LaneEnemy(0, 0)..x = 1.5);
      game.enemies.add(LaneEnemy(1, 0)..x = 3);
      advance(game, 301);
      expect(game.kills, 1);
      expect(game.enemies, hasLength(1));
      expect(game.enemies.single.row, 1);
      expect(game.enemies.single.hp, 100);
    },
  );

  test('one safety clear is available per lane, a second breach loses', () {
    final game = LaneDefense();
    game.enemies.add(LaneEnemy(0, 0)..x = 0.001);
    advance(game, 1);
    expect(game.safety, [false, true, true]);
    expect(game.kills, 1);
    expect(game.result, isNull);
    game.enemies.add(LaneEnemy(0, 0)..x = 0.001);
    advance(game, 1);
    expect(game.result, '防线失守');
    final time = game.time;
    advance(game, 60);
    expect(game.time, time);
    expect(game.plant(1, 0, 0), isFalse);
    expect(game.collect(), 0);
  });

  test('five completed waves with no live or scheduled targets win', () {
    final game = LaneDefense();
    for (var i = 0; i < 4200 && game.result == null; i++) {
      for (final enemy in game.enemies) {
        enemy.hp = 0;
      }
      game.tick(1 / 60);
    }
    expect(game.wave, 5);
    expect(game.scheduled, isEmpty);
    expect(game.enemies, isEmpty);
    expect(game.kills, 15);
    expect(game.result, '守线成功');
  });

  test('save restore continues the exact same fixed-step simulation', () {
    final game = LaneDefense(2)..plant(0, 0, 0);
    advance(game, 601);
    game.collect();
    expect(game.plant(1, 0, 1), isTrue);
    advance(game, 240);
    final restored = LaneDefense.fromJson(snapshot(game))!;
    expect(restored.toJson(), game.toJson());
    advance(game, 600);
    advance(restored, 600);
    expect(restored.toJson(), game.toJson());
  });

  test('invalid version, nonfinite time and malformed entity saves fail', () {
    final game = LaneDefense()..plant(0, 0, 0);
    final duplicate = snapshot(game);
    (duplicate['units'] as List).add((duplicate['units'] as List).first);
    final invalidHp = snapshot(game);
    ((invalidHp['units'] as List).first as Map)['hp'] = -1;
    for (final bad in [
      duplicate,
      invalidHp,
      {...snapshot(game), 'version': 2},
      {...snapshot(game), 'level': 3},
      {...snapshot(game), 'time': double.nan},
      {...snapshot(game), 'energy': -1},
      {...snapshot(game), 'wave': 6},
      {
        ...snapshot(game),
        'safety': [true],
      },
      {
        ...snapshot(game),
        'scheduled': [
          {'at': 1, 'row': 3, 'type': 0},
        ],
      },
    ]) {
      expect(LaneDefense.fromJson(bad), isNull);
    }
  });
}
