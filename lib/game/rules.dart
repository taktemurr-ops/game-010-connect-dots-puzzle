import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'flow_engine.dart';

class FlowRules extends GameRules<FlowLevel> {
  @override
  String get gameId => 'game-010-connect-dots-puzzle';

  @override
  List<String> get optionalMechanics => const ['timer', 'big'];

  @override
  List<GameModeId> get modes => const [
        GameModeId.campaign,
        GameModeId.endless,
        GameModeId.timeAttack,
        GameModeId.zen,
        GameModeId.daily,
        GameModeId.weekly,
        GameModeId.challenge,
      ];

  @override
  List<GameStat> get gameStats => const [
        GameStat('paths_connected', 'Bağlanan yol', 'Paths connected', scale: 50),
        GameStat('perfect_boards', 'Kusursuz tahta', 'Perfect boards', scale: 5),
        GameStat('cells_painted', 'Doldurulan kare', 'Cells filled', scale: 200),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('paths', 'paths_connected', [20, 50, 100]),
        MissionTemplate('perfect', 'perfect_boards', [2, 4, 6], coinReward: 70),
      ];

  @override
  FlowLevel generate(LevelSpec spec) => generateFlow(spec);

  @override
  Validation validate(FlowLevel l, LevelSpec spec) {
    final seen = <int>{};
    for (final p in l.solution) {
      if (p.length < 3) return const Validation.fail('short path');
      for (var k = 0; k < p.length; k++) {
        if (!seen.add(p[k])) return const Validation.fail('overlap');
        if (k > 0 && !adjacent(p[k - 1], p[k], l.n)) return const Validation.fail('gap');
      }
    }
    if (seen.length != l.n * l.n) return const Validation.fail('not covering');
    if (l.colors < 3 || l.colors > 16) return const Validation.fail('colors');
    // A dot next to its own partner would be trivial.
    for (final p in l.solution) {
      if (adjacent(p.first, p.last, l.n)) return const Validation.fail('trivial pair');
    }
    return Validation.ok(l.colors);
  }

  static int stars(FlowGame g) {
    if (!g.won) return 0;
    if (g.perfect && g.moves <= g.level.colors) return 3;
    if (g.perfect) return 2;
    return 1;
  }
}

GameRules createRules() => FlowRules();
