import 'package:flutter/material.dart';

void main() => runApp(const ConnectDotsApp());

class DotPathGame {
  DotPathGame(this.size, this.solution)
      : assert(size > 1),
        assert(solution.length > 1);

  final int size;
  final List<int> solution;
  final List<int> path = [];

  bool get completed =>
      path.length == solution.length &&
      List.generate(path.length, (i) => path[i] == solution[i]).every((v) => v);

  bool get started => path.isNotEmpty;

  bool tap(int cell) {
    if (cell < 0 || cell >= size * size || completed) return false;
    if (path.isEmpty) {
      if (cell != solution.first) return false;
      path.add(cell);
      return true;
    }
    if (path.last == cell) return false;
    if (path.length > 1 && path[path.length - 2] == cell) {
      path.removeLast();
      return true;
    }
    if (path.contains(cell)) return false;
    final last = path.last;
    final rowDistance = (last ~/ size - cell ~/ size).abs();
    final colDistance = (last % size - cell % size).abs();
    if (rowDistance + colDistance != 1) return false;
    if (solution[path.length] != cell) return false;
    path.add(cell);
    return true;
  }

  void restart() => path.clear();
}

DotPathGame createLevel(int level) {
  if (level.isEven) {
    return DotPathGame(4, [0, 1, 2, 6, 10, 9, 8, 12, 13, 14, 15]);
  }
  return DotPathGame(4, [3, 2, 1, 5, 9, 13, 14, 10, 6, 7, 11, 15]);
}

class ConnectDotsApp extends StatelessWidget {
  const ConnectDotsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Connect Dots Puzzle',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const ConnectDotsScreen(),
      );
}

class ConnectDotsScreen extends StatefulWidget {
  const ConnectDotsScreen({super.key});

  @override
  State<ConnectDotsScreen> createState() => _ConnectDotsScreenState();
}

class _ConnectDotsScreenState extends State<ConnectDotsScreen> {
  int level = 0;
  late DotPathGame game = createLevel(level);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Connect Dots Puzzle')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Level ${level + 1}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('Connect the numbered dots in order. Tap the previous dot to undo.'),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: game.size * game.size,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: game.size,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final step = game.solution.indexOf(index);
                        final visited = game.path.contains(index);
                        final isEndpoint = step == 0 || step == game.solution.length - 1;
                        return Semantics(
                          label: step >= 0 ? 'Dot ${step + 1}, ${visited ? 'connected' : 'unconnected'}' : 'Empty cell',
                          button: step >= 0,
                          child: InkWell(
                            key: ValueKey('dot-$index'),
                            onTap: step < 0 ? null : () => setState(() => game.tap(index)),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: visited ? Colors.indigo.shade400 : Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isEndpoint ? Colors.deepOrange : Colors.indigo.shade200,
                                  width: isEndpoint ? 3 : 1,
                                ),
                              ),
                              child: Center(
                                child: step < 0 ? const SizedBox.shrink() : Text(
                                  '${step + 1}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: visited ? Colors.white : Colors.indigo.shade900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(game.completed
                      ? 'Puzzle completed!'
                      : 'Connected ${game.path.length} / ${game.solution.length}',
                      key: const ValueKey('progress')),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, children: [
                    OutlinedButton(
                      onPressed: () => setState(game.restart),
                      child: const Text('Restart'),
                    ),
                    FilledButton(
                      onPressed: game.completed ? () => setState(() {
                        level++;
                        game = createLevel(level);
                      }) : null,
                      child: const Text('Next level'),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      );
}
