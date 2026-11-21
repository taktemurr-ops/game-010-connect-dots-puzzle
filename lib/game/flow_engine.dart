import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

class FlowLevel {
  final int n;

  /// Solution paths (cell indices) per color; endpoints are the dots.
  final List<List<int>> solution;
  final int timeLimit;
  final int difficulty;
  final int seed;

  const FlowLevel({
    required this.n,
    required this.solution,
    required this.timeLimit,
    required this.difficulty,
    required this.seed,
  });

  int get colors => solution.length;

  /// cell -> color of the dot on that cell, or -1.
  Map<int, int> get dots => {
        for (var c = 0; c < solution.length; c++) ...{solution[c].first: c, solution[c].last: c}
      };
}

bool adjacent(int a, int b, int n) {
  final ax = a % n, ay = a ~/ n, bx = b % n, by = b ~/ n;
  return (ax - bx).abs() + (ay - by).abs() == 1;
}

/// Random Hamiltonian path with the backbite algorithm (seeded).
List<int> hamiltonianPath(int n, SeededRandom r) {
  var path = <int>[];
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      path.add(y * n + (y.isEven ? x : n - 1 - x));
    }
  }
  final steps = n * n * 12;
  for (var s = 0; s < steps; s++) {
    if (r.chance(0.5)) path = path.reversed.toList();
    final head = path.first;
    final hx = head % n, hy = head ~/ n;
    final nbs = <int>[];
    if (hx > 0) nbs.add(head - 1);
    if (hx < n - 1) nbs.add(head + 1);
    if (hy > 0) nbs.add(head - n);
    if (hy < n - 1) nbs.add(head + n);
    final v = r.pick(nbs);
    final i = path.indexOf(v);
    if (i <= 1) continue;
    path = [...path.sublist(0, i).reversed, ...path.sublist(i)];
  }
  return path;
}

FlowLevel generateFlow(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  const sizes = [5, 5, 6, 6, 7, 7, 8, 8, 9, 10];
  var n = sizes[(d - 1).clamp(0, 9)];
  if (spec.has('big')) n = (n + 2).clamp(5, 12);
  final path = hamiltonianPath(n, r);
  // Cut into segments: fewer, longer paths are harder.
  final total = path.length;
  final targetColors = (n + 1 - (d ~/ 4)).clamp(4, 14);
  final avg = total / targetColors;
  final segs = <List<int>>[];
  var i = 0;
  while (i < total) {
    var len = (avg * (0.6 + r.nextDouble() * 0.8)).round().clamp(3, total);
    if (total - (i + len) < 3) len = total - i;
    segs.add(path.sublist(i, i + len));
    i += len;
  }
  return FlowLevel(
    n: n,
    solution: segs,
    timeLimit: spec.mode == GameModeId.timeAttack ? 60 + n * 6 : (spec.has('timer') ? 30 + n * n * 2 : 0),
    difficulty: d,
    seed: spec.seed,
  );
}

class FlowGame {
  final FlowLevel level;
  late List<List<int>> paths; // player paths per color
  int moves = 0;
  final List<String> _undo = [];

  FlowGame(this.level) {
    paths = List.generate(level.colors, (_) => <int>[]);
  }

  int get n => level.n;
  late final Map<int, int> dots = level.dots;

  /// color owning a cell (path or dot), -1 if free.
  int owner(int cell) {
    final d = dots[cell];
    if (d != null) return d;
    for (var c = 0; c < paths.length; c++) {
      if (paths[c].contains(cell)) return c;
    }
    return -1;
  }

  bool connected(int c) {
    final p = paths[c];
    if (p.length < 2) return false;
    final ends = {level.solution[c].first, level.solution[c].last};
    return ends.contains(p.first) && ends.contains(p.last) && p.first != p.last;
  }

  int get connectedCount => List.generate(paths.length, connected).where((e) => e).length;

  bool get allConnected => connectedCount == paths.length;

  int get filledCells {
    final s = <int>{};
    for (final p in paths) {
      s.addAll(p);
    }
    s.addAll(dots.keys);
    return s.length;
  }

  bool get perfect => allConnected && filledCells == n * n;

  bool get won => allConnected;

  // ---- Drawing ---------------------------------------------------------------
  int _active = -1;

  /// Start drawing from a dot or from the end of an existing path.
  bool begin(int cell) {
    final d = dots[cell];
    if (d != null) {
      _push();
      _active = d;
      paths[d] = [cell];
      return true;
    }
    for (var c = 0; c < paths.length; c++) {
      final idx = paths[c].indexOf(cell);
      if (idx >= 0) {
        _push();
        _active = c;
        paths[c] = paths[c].sublist(0, idx + 1);
        return true;
      }
    }
    return false;
  }

  /// Extends the active path into [cell] if possible.
  bool extend(int cell) {
    if (_active < 0) return false;
    final p = paths[_active];
    if (p.isEmpty || p.last == cell) return false;
    // Moving back along own path shortens it.
    final back = p.indexOf(cell);
    if (back >= 0) {
      paths[_active] = p.sublist(0, back + 1);
      return true;
    }
    if (!adjacent(p.last, cell, n)) return false;
    if (connected(_active)) return false;
    final d = dots[cell];
    if (d != null && d != _active) return false;
    // Cut through another color's path.
    for (var c = 0; c < paths.length; c++) {
      if (c == _active) continue;
      final k = paths[c].indexOf(cell);
      if (k >= 0) paths[c] = paths[c].sublist(0, k);
    }
    p.add(cell);
    return true;
  }

  void end() {
    if (_active >= 0) moves++;
    _active = -1;
  }

  /// Hint: draws one unsolved path from the solution.
  int? solveOne() {
    for (var c = 0; c < paths.length; c++) {
      if (connected(c)) continue;
      _push();
      final sol = level.solution[c];
      for (var o = 0; o < paths.length; o++) {
        if (o == c) continue;
        final cut = paths[o].indexWhere(sol.contains);
        if (cut >= 0) paths[o] = paths[o].sublist(0, cut);
      }
      paths[c] = List.of(sol);
      return c;
    }
    return null;
  }

  void _push() {
    _undo.add(_snap());
    if (_undo.length > 60) _undo.removeAt(0);
  }

  bool get canUndo => _undo.isNotEmpty;
  void undo() {
    if (_undo.isNotEmpty) _restore(_undo.removeLast());
  }

  String _snap() => '${paths.map((p) => p.join(',')).join('|')}#$moves';
  void _restore(String s) {
    final parts = s.split('#');
    paths = parts[0].split('|').map((p) => p.isEmpty ? <int>[] : p.split(',').map(int.parse).toList()).toList();
    moves = int.parse(parts[1]);
  }

  String serialize() => _snap();
  static FlowGame restore(FlowLevel l, String s) => FlowGame(l).._restore(s);
}
