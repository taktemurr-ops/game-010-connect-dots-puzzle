import 'package:flutter_test/flutter_test.dart';
import 'package:game_010_connect_dots_puzzle/main.dart';

void main() {
  test('path starts at the first dot and follows the prescribed route', () {
    final game = createLevel(0);
    expect(game.tap(1), isFalse);
    expect(game.started, isFalse);
    for (final cell in game.solution) {
      expect(game.tap(cell), isTrue);
    }
    expect(game.completed, isTrue);
    expect(game.tap(game.solution.last), isFalse);
    game.restart();
    expect(game.started, isFalse);
    expect(game.completed, isFalse);
  });

  test('backtracking removes only the previous step', () {
    final game = createLevel(0);
    expect(game.tap(0), isTrue);
    expect(game.tap(1), isTrue);
    expect(game.tap(0), isTrue);
    expect(game.path, [0]);
    expect(game.tap(-1), isFalse);
    expect(game.tap(16), isFalse);
    expect(game.tap(6), isFalse);
  });
}
