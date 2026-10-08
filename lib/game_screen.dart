import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'puzzles.dart';

/// Crossword — 5 hand-generated mini crosswords with across/down clues,
/// tap-to-select words, an A-Z letter strip, check & reveal helpers.
class CrosswordScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const CrosswordScreen({super.key, required this.players, required this.callbacks});

  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _Entry {
  final String dir; // 'A' or 'D'
  final int num;
  final String word;
  final int r, c;
  final String clue;
  const _Entry(this.dir, this.num, this.word, this.r, this.c, this.clue);

  List<Point> get cells => [
        for (int i = 0; i < word.length; i++)
          dir == 'A' ? Point(r, c + i) : Point(r + i, c),
      ];
}

class Point {
  final int r, c;
  const Point(this.r, this.c);
  @override
  bool operator ==(Object other) => other is Point && other.r == r && other.c == c;
  @override
  int get hashCode => r * 97 + c;
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  int puzzleIdx = 0;
  late int n;
  late List<String> solRows;
  late List<_Entry> entries;
  late List<List<String>> grid; // user letters
  _Entry? sel;
  int cursor = 0;
  final Set<String> wrongCells = {}; // "r,c"
  final Set<int> revealed = {}; // entry indices
  int hintsUsed = 0;
  bool over = false;

  int get whiteCount =>
      solRows.fold(0, (a, row) => a + row.split('').where((ch) => ch != '.').length);
  int get filledCount => grid
      .expand((row) => row)
      .where((ch) => ch.isNotEmpty)
      .length;

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  void _load(int idx) {
    final p = kCrosswordPuzzles[idx];
    n = (p['rows'] as List).length;
    solRows = List<String>.from(p['rows'] as List);
    entries = [
      for (final e in (p['entries'] as List))
        _Entry(e['d'] as String, e['n'] as int, e['w'] as String,
            e['r'] as int, e['c'] as int, e['clue'] as String),
    ]..sort((a, b) => a.num.compareTo(b.num));
    grid = List.generate(n, (_) => List.filled(n, ''));
    wrongCells.clear();
    revealed.clear();
    hintsUsed = 0;
    over = false;
    sel = entries.firstWhere((e) => e.dir == 'A', orElse: () => entries.first);
    cursor = 0;
  }

  String _sol(int r, int c) => solRows[r][c];
  bool _white(int r, int c) => _sol(r, c) != '.';

  _Entry? _entryAt(int r, int c, String dir) {
    for (final e in entries) {
      if (e.dir != dir) continue;
      if (e.cells.any((p) => p.r == r && p.c == c)) return e;
    }
    return null;
  }

  void _tapCell(int r, int c) {
    if (over || !_white(r, c)) return;
    Sfx.tap();
    final a = _entryAt(r, c, 'A');
    final d = _entryAt(r, c, 'D');
    setState(() {
      wrongCells.clear();
      final curCell = sel == null
          ? null
          : sel!.cells[cursor.clamp(0, sel!.cells.length - 1)];
      if (curCell != null && curCell.r == r && curCell.c == c && a != null && d != null) {
        // tapped same cell again: toggle direction
        final ni = entries.indexOf(sel!);
        sel = _entryAt(r, c, sel!.dir == 'A' ? 'D' : 'A') ?? sel;
        cursor = sel!.cells.indexWhere((p) => p.r == r && p.c == c).clamp(0, 99);
        if (cursor < 0) cursor = 0;
        debugPrint('$ni');
      } else {
        _Entry? pick;
        if (sel != null && (a == sel || d == sel)) {
          pick = (a == sel) ? a : d;
        } else {
          pick = (sel?.dir == 'A' ? a : d) ?? a ?? d;
        }
        sel = pick;
        cursor = sel!.cells.indexWhere((p) => p.r == r && p.c == c);
        if (cursor < 0) cursor = 0;
      }
    });
  }

  void _type(String ch) {
    if (over || sel == null) return;
    final cells = sel!.cells;
    if (cursor >= cells.length) return;
    Sfx.click();
    setState(() {
      final p = cells[cursor];
      grid[p.r][p.c] = ch;
      wrongCells.remove('${p.r},${p.c}');
      if (cursor < cells.length - 1) cursor++;
      _checkWin();
    });
  }

  void _backspace() {
    if (over || sel == null) return;
    Sfx.tap();
    setState(() {
      final cells = sel!.cells;
      var p = cells[cursor];
      if (grid[p.r][p.c].isEmpty && cursor > 0) {
        cursor--;
        p = cells[cursor];
      }
      grid[p.r][p.c] = '';
      wrongCells.remove('${p.r},${p.c}');
    });
  }

  void _check() {
    if (over) return;
    Sfx.click();
    setState(() {
      wrongCells.clear();
      var bad = 0;
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          if (!_white(r, c) || grid[r][c].isEmpty) continue;
          if (grid[r][c] != _sol(r, c)) {
            wrongCells.add('$r,$c');
            bad++;
          }
        }
      }
      if (bad == 0 && filledCount == whiteCount) {
        _win();
      } else if (bad == 0) {
        widget.players.first.score += 5;
        widget.callbacks.refreshHud();
      }
    });
    if (wrongCells.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => wrongCells.clear());
      });
    }
  }

  void _reveal() {
    if (over || sel == null || revealed.contains(entries.indexOf(sel!))) return;
    Sfx.move();
    setState(() {
      hintsUsed++;
      revealed.add(entries.indexOf(sel!));
      for (final p in sel!.cells) {
        grid[p.r][p.c] = _sol(p.r, p.c);
        wrongCells.remove('${p.r},${p.c}');
      }
      _checkWin();
    });
  }

  void _clearWord() {
    if (over || sel == null) return;
    Sfx.tap();
    setState(() {
      for (final p in sel!.cells) {
        grid[p.r][p.c] = '';
      }
      revealed.remove(entries.indexOf(sel!));
      cursor = 0;
    });
  }

  void _checkWin() {
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_white(r, c) && grid[r][c] != _sol(r, c)) return;
      }
    }
    _win();
  }

  void _win() {
    if (over) return;
    over = true;
    Sfx.win();
    final bonus = (5 - hintsUsed).clamp(0, 5) * 10;
    widget.players.first.score += 100 + bonus;
    widget.callbacks.refreshHud();
    final titles = ['Pet Pals', 'Cosmic Trip', 'Tasty Treats', 'Wild Kingdom', 'Sweet & Savory'];
    widget.callbacks.finish(
      headline: 'Crossword cracked! 📝🎉',
      subline:
          '${titles[puzzleIdx]} complete with $hintsUsed reveal${hintsUsed == 1 ? '' : 's'}. +${100 + bonus} pts — crossword champion energy!',
    );
  }

  void _nextWord(int dirn) {
    if (sel == null) return;
    Sfx.tap();
    setState(() {
      final i = entries.indexOf(sel!);
      sel = entries[(i + dirn + entries.length) % entries.length];
      cursor = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final titles = ['Pet Pals 🐾', 'Cosmic Trip 🚀', 'Tasty Treats 🍩', 'Wild Kingdom 🦁', 'Sweet & Savory 🍬'];
    return Column(
      children: [
        // puzzle picker
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(titles[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              selected: i == puzzleIdx,
              onSelected: (_) {
                if (i == puzzleIdx || over) return;
                Sfx.tap();
                setState(() {
                  puzzleIdx = i;
                  _load(i);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        // progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: whiteCount == 0 ? 0 : filledCount / whiteCount,
              minHeight: 8,
              backgroundColor: t.surface,
              valueColor: AlwaysStoppedAnimation(t.primary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // clue banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _nextWord(-1)),
                Expanded(
                  child: sel == null
                      ? const SizedBox()
                      : Text(
                          '${sel!.num}${sel!.dir == 'A' ? '→' : '↓'}  ${sel!.clue}',
                          style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _nextWord(1)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // grid
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: n,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: n * n,
                  itemBuilder: (_, i) => _cell(i ~/ n, i % n, t),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: WajihaButton(label: 'Check', emoji: '✅', onTap: _check)),
              const SizedBox(width: 8),
              Expanded(child: WajihaButton(label: 'Reveal', emoji: '💡', onTap: _reveal, primary: false)),
              const SizedBox(width: 8),
              Expanded(child: WajihaButton(label: 'Clear', emoji: '🧽', onTap: _clearWord, primary: false)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // A-Z strip
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (int i = 0; i < 26; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _key(String.fromCharCode(65 + i), t),
                ),
              _key('⌫', t, back: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _key(String ch, GameTheme t, {bool back = false}) {
    return GestureDetector(
      onTap: () => back ? _backspace() : _type(ch),
      child: Container(
        width: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: back ? t.secondary.withValues(alpha: 0.25) : t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.primary.withValues(alpha: 0.35)),
        ),
        child: Text(ch,
            style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
    );
  }

  Widget _cell(int r, int c, GameTheme t) {
    if (!_white(r, c)) return const SizedBox();
    final inSel = sel != null && sel!.cells.any((p) => p.r == r && p.c == c);
    final isCursor = inSel &&
        sel!.cells[cursor.clamp(0, sel!.cells.length - 1)].r == r &&
        sel!.cells[cursor.clamp(0, sel!.cells.length - 1)].c == c;
    final wrong = wrongCells.contains('$r,$c');
    // number label: does any entry start here?
    int? num;
    for (final e in entries) {
      if (e.r == r && e.c == c) {
        num = e.num;
        break;
      }
    }
    final letter = grid[r][c];
    return GestureDetector(
      onTap: () => _tapCell(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: wrong
              ? const Color(0xFFFF6B6B).withValues(alpha: 0.75)
              : isCursor
                  ? t.accent.withValues(alpha: 0.85)
                  : inSel
                      ? t.primary.withValues(alpha: 0.35)
                      : t.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isCursor ? t.accent : t.primary.withValues(alpha: 0.25),
            width: isCursor ? 2.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (num != null)
              Positioned(
                left: 3,
                top: 1,
                child: Text('$num',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isCursor ? Colors.white : t.muted)),
              ),
            Center(
              child: Text(letter,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: wrong
                          ? Colors.white
                          : isCursor
                              ? Colors.white
                              : t.text)),
            ),
          ],
        ),
      ),
    );
  }
}
