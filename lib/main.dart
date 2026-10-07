import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const CrosswordApp());

class CrosswordApp extends StatelessWidget {
  const CrosswordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Crossword',
      tagline: 'Tiny crosswords, giant brain energy. Crack all five!',
      emoji: '📝',
      slug: 'crossword',
      howToPlay:
          '• Pick one of 5 mini crosswords: animals, space & food themes.\n• Tap a square to select its word — tap the same square again to flip across ↕ down.\n• Type letters with the A–Z strip; ⌫ erases.\n• Use ✅ Check to spot mistakes and 💡 Reveal when you\'re truly stuck.\n• Fill every square correctly to win. No timer, just vibes. 🧠',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          CrosswordScreen(players: players, callbacks: cb),
    );
  }
}
