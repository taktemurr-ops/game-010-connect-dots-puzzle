import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'flow_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-010-connect-dots-puzzle',
  title: const ['Noktaları Birleştir', 'Connect Dots Puzzle', 'Punkte Verbinden', 'Une los Puntos', 'Reliez les Points'],
  tagline: const [
    'Aynı renkleri birleştir, tüm tahtayı doldur!',
    'Connect matching colors, fill the whole board!',
    'Verbinde gleiche Farben, fülle das Brett!',
    '¡Une colores iguales y llena el tablero!',
    'Reliez les couleurs, remplissez la grille !',
  ],
  seedColor: const Color(0xFFE53935),
  icon: Icons.timeline,
  rules: FlowRules(),
  buildPlay: (ctx) => FlowView(ctx: ctx),
  tutorial: const [
    TutorialStep(Icons.gesture, [
      'Bir noktadan başlayıp aynı renkteki diğer noktaya parmağınla yol çiz.',
      'Drag from a dot to the dot of the same color to draw a pipe.',
      'Ziehe von einem Punkt zum gleichfarbigen Punkt.',
      'Arrastra de un punto al del mismo color.',
      'Glissez d\'un point au point de même couleur.',
    ]),
    TutorialStep(Icons.do_not_disturb, [
      'Yollar kesişemez; başka bir yolun üstünden geçersen o yol kesilir.',
      'Pipes cannot cross; drawing over another pipe cuts it.',
      'Rohre kreuzen sich nicht.',
      'Las tuberías no se cruzan.',
      'Les tuyaux ne se croisent pas.',
    ]),
    TutorialStep(Icons.format_color_fill, [
      'Tüm renkleri bağla ve her kareyi doldur: kusursuz tahta = 3 yıldız!',
      'Connect all colors and fill every cell: a perfect board = 3 stars!',
      'Alle verbinden und jedes Feld füllen = 3 Sterne!',
      'Conecta todo y llena cada casilla = 3 estrellas.',
      'Tout relier et tout remplir = 3 étoiles !',
    ]),
  ],
);
