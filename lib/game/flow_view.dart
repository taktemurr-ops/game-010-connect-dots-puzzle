import 'package:flutter/material.dart';

import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';
import 'flow_engine.dart';
import 'rules.dart';

/// Draw lines between matching dots; lines may not cross. Fill the board.
class FlowView extends StatefulWidget {
  final PlayContext ctx;
  const FlowView({super.key, required this.ctx});

  @override
  State<FlowView> createState() => _FlowViewState();
}

class _FlowViewState extends State<FlowView> with RoundClock {
  late FlowGame game;
  int _hints = 0;
  int _undos = 0;
  int _solved = 0;
  int _connectedTotal = 0;
  int _perfectTotal = 0;
  bool _ended = false;
  int _connectedBefore = 0;

  PlayContext get ctx => widget.ctx;
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack, GameModeId.zen].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    final level = (ctx.generated as GeneratedLevel<FlowLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? FlowGame.restore(level, snap) : FlowGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _solved = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    startClock(initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0, limit: level.timeLimit);
  }

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end(_chain ? _solved > 0 : game.won);

  void _persist() => ctx.saveResume({'snap': game.serialize(), 'secs': seconds, 'hints': _hints, 'solved': _solved});

  List<Color> get _colors {
    final base = ctx.pieceColors;
    return [
      for (var i = 0; i < 16; i++)
        i < base.length ? base[i] : HSLColor.fromAHSL(1, (i * 47 + 15) % 360.0, 0.7, i.isEven ? 0.45 : 0.68).toColor()
    ];
  }

  int? _cellAt(Offset p, double cell) {
    final x = (p.dx / cell).floor(), y = (p.dy / cell).floor();
    if (x < 0 || y < 0 || x >= game.n || y >= game.n) return null;
    return y * game.n + x;
  }

  void _start(Offset p, double cell) {
    final c = _cellAt(p, cell);
    if (c == null || _ended) return;
    _connectedBefore = game.connectedCount;
    if (game.begin(c)) {
      ctx.sfx(Sfx.tap);
      setState(() {});
    }
  }

  void _move(Offset p, double cell) {
    final c = _cellAt(p, cell);
    if (c == null) return;
    if (game.extend(c)) setState(() {});
  }

  void _finishStroke() {
    game.end();
    final gained = game.connectedCount - _connectedBefore;
    if (gained > 0) {
      _connectedTotal += gained;
      ctx.sfx(Sfx.clear);
    }
    setState(() {});
    _persist();
    if (game.won && (game.perfect || ctx.spec.mode != GameModeId.zen)) _solvedBoard();
  }

  void _solvedBoard() {
    if (game.perfect) _perfectTotal++;
    ctx.sfx(Sfx.combo);
    if (_chain) {
      _solved++;
      final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _solved]));
      setState(() => game = FlowGame(FlowRules().build(next).puzzle));
      _persist();
      return;
    }
    _end(true);
  }

  void _end(bool won) {
    if (_ended) return;
    _ended = true;
    stopClock();
    final stars = _chain ? (_solved >= 6 ? 3 : _solved >= 3 ? 2 : 1) : FlowRules.stars(game);
    ctx.finish(RoundResult(
      won: won,
      score: _chain ? _solved * 400 : (won ? game.filledCells * 10 + (game.perfect ? 500 : 0) : 0),
      stars: won ? stars : 0,
      seconds: seconds,
      moves: game.moves,
      hintsUsed: _hints,
      undosUsed: _undos,
      gameStats: {
        'paths_connected': _connectedTotal,
        'perfect_boards': _perfectTotal,
        'cells_painted': game.filledCells,
      },
    ));
  }

  Future<void> _hint() async {
    if (!await ctx.requestHint()) return;
    _hints++;
    final before = game.connectedCount;
    setState(() => game.solveOne());
    _connectedTotal += (game.connectedCount - before).clamp(0, 99);
    _persist();
    if (game.won) _solvedBoard();
  }

  @override
  Widget build(BuildContext context) {
    final t = ctx.t;
    final colors = _colors;
    return Column(children: [
      PlayHud(items: [
        (Icons.link, '${game.connectedCount}/${game.level.colors}'),
        (Icons.format_color_fill, '${(game.filledCells * 100 / (game.n * game.n)).round()}%'),
        (Icons.timer, timeText),
        if (_chain) (Icons.emoji_events, '$_solved'),
      ]),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final side = (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 16;
          final cell = side / game.n;
          return Center(
            child: GestureDetector(
              onPanStart: (d) => _start(d.localPosition, cell),
              onPanUpdate: (d) => _move(d.localPosition, cell),
              onPanEnd: (_) => _finishStroke(),
              child: Semantics(
                label: 'connect board ${game.n} by ${game.n}',
                child: CustomPaint(
                  size: Size(side, side),
                  painter: _FlowPainter(game, colors, ctx.colorBlind, ctx.symbol),
                ),
              ),
            ),
          );
        }),
      ),
      BoosterBar(buttons: [
        BoosterButton(Icons.lightbulb, t('hint'), _hint),
        BoosterButton(Icons.undo, t('undo'), game.canUndo
            ? () {
                setState(() {
                  game.undo();
                  _undos++;
                });
                _persist();
              }
            : null),
        BoosterButton(Icons.refresh, t('restart'), () {
          setState(() {
            for (var k = 0; k < game.paths.length; k++) {
              game.paths[k] = [];
            }
          });
          _persist();
        }),
      ]),
    ]);
  }
}

class _FlowPainter extends CustomPainter {
  final FlowGame g;
  final List<Color> colors;
  final bool colorBlind;
  final String Function(int) symbol;
  _FlowPainter(this.g, this.colors, this.colorBlind, this.symbol);

  @override
  void paint(Canvas canvas, Size size) {
    final n = g.n;
    final c = size.width / n;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
        Paint()..color = Colors.black.withValues(alpha: 0.55));
    // Filled cell tint
    for (var col = 0; col < g.paths.length; col++) {
      for (final cell in g.paths[col]) {
        final x = cell % n, y = cell ~/ n;
        canvas.drawRect(Rect.fromLTWH(x * c, y * c, c, c),
            Paint()..color = colors[col % colors.length].withValues(alpha: 0.22));
      }
    }
    final grid = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var k = 0; k <= n; k++) {
      canvas.drawLine(Offset(k * c, 0), Offset(k * c, size.height), grid);
      canvas.drawLine(Offset(0, k * c), Offset(size.width, k * c), grid);
    }
    Offset center(int cell) => Offset((cell % n + 0.5) * c, (cell ~/ n + 0.5) * c);
    for (var col = 0; col < g.paths.length; col++) {
      final p = g.paths[col];
      if (p.length < 2) continue;
      final paint = Paint()
        ..color = colors[col % colors.length]
        ..strokeWidth = c * 0.32
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(center(p.first).dx, center(p.first).dy);
      for (final cell in p.skip(1)) {
        path.lineTo(center(cell).dx, center(cell).dy);
      }
      canvas.drawPath(path, paint);
    }
    g.dots.forEach((cell, col) {
      canvas.drawCircle(center(cell), c * 0.36, Paint()..color = colors[col % colors.length]);
      if (g.connected(col)) {
        canvas.drawCircle(center(cell), c * 0.36,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
      if (colorBlind) paintText(canvas, symbol(col), center(cell), c * 0.36, Colors.white);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
