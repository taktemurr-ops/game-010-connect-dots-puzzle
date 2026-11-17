import 'package:flutter_test/flutter_test.dart';
import 'package:game_010_connect_dots_puzzle/main.dart';

void main() {
  group('DotPathGame', () {
    test('rejects invalid start, out-of-range and nonadjacent moves', () {
      final game = createLevel(0);
      expect(game.tap(-1), isFalse);
      expect(game.tap(16), isFalse);
      expect(game.tap(1), isFalse);
      expect(game.tap(0), isTrue);
      expect(game.tap(2), isFalse);
      expect(game.path, [0]);
    });

    test('can undo one step and restart without losing solution', () {
      final game = createLevel(0);
      expect(game.tap(0), isTrue);
      expect(game.tap(1), isTrue);
      expect(game.tap(0), isTrue);
      expect(game.path, [0]);
      game.restart();
      expect(game.path, isEmpty);
      expect(game.completed, isFalse);
    });

    for (final level in [0, 1]) {
      test('level $level has adjacent unique steps and can be completed', () {
        final game = createLevel(level);
        expect(game.solution.toSet().length, game.solution.length);
        for (final cell in game.solution) {
          expect(game.tap(cell), isTrue, reason: 'cell $cell');
        }
        expect(game.completed, isTrue);
        expect(game.tap(game.solution.last), isFalse);
      });
    }
  });
}
