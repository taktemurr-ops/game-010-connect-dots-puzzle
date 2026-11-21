import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';
import 'package:game_010_connect_dots_puzzle/game/flow_engine.dart';
import 'package:game_010_connect_dots_puzzle/game/rules.dart';

void main() {
  final rules = FlowRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('backbite keeps a valid Hamiltonian path', () {
    for (var n = 5; n <= 10; n++) {
      final p = hamiltonianPath(n, SeededRandom(n));
      expect(p.toSet().length, n * n);
      for (var k = 1; k < p.length; k++) {
        expect(adjacent(p[k - 1], p[k], n), isTrue);
      }
    }
  });

  test('drawing: extend, cut other colors, back-track, connect', () {
    final l = rules.build(planner.spec(3)).puzzle;
    final g = FlowGame(l);
    final sol = l.solution[0];
    expect(g.begin(sol.first), isTrue);
    for (final c in sol.skip(1)) {
      expect(g.extend(c), isTrue);
    }
    g.end();
    expect(g.connected(0), isTrue);
    // Back-track shortens the path.
    g.begin(sol[1]);
    g.end();
    expect(g.connected(0), isFalse);
  });

  test('solving every path from the solution is perfect', () {
    final l = rules.build(planner.spec(50)).puzzle;
    final g = FlowGame(l);
    while (g.solveOne() != null) {}
    expect(g.won, isTrue);
    expect(g.perfect, isTrue);
  });

  test('resume restores state', () {
    final l = rules.build(planner.spec(8)).puzzle;
    final g = FlowGame(l)..solveOne();
    expect(FlowGame.restore(l, g.serialize()).serialize(), g.serialize());
  });

  test('levels 1..300 valid', () {
    for (var n = 1; n <= 300; n++) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });
}
