import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_010_connect_dots_puzzle/main.dart';

void main() {
  test('path must start at first dot and follow adjacent ordered cells', () {
    final game = createLevel(0);
    expect(game.tap(1), isFalse);
    expect(game.tap(0), isTrue);
    expect(game.tap(2), isFalse);
    expect(game.tap(1), isTrue);
    expect(game.tap(2), isTrue);
    expect(game.path, [0, 1, 2]);
  });

  test('backtracking and restart work', () {
    final game = createLevel(0);
    game.tap(0);
    game.tap(1);
    expect(game.tap(0), isTrue);
    expect(game.path, [0]);
    game.restart();
    expect(game.path, isEmpty);
  });

  test('full ordered path completes the level', () {
    final game = createLevel(0);
    for (final cell in game.solution) {
      expect(game.tap(cell), isTrue);
    }
    expect(game.completed, isTrue);
    expect(game.tap(0), isFalse);
  });

  testWidgets('game shows grid and restart button', (tester) async {
    await tester.pumpWidget(const ConnectDotsApp());
    expect(find.byKey(const ValueKey('dot-0')), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
  });
}
