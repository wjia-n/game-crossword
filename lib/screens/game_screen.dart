import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/crossword_engine.dart';
import '../puzzles.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/morning_press.dart';
import '../theme/press_themes.dart';

/// Crossword play screen. The [CrosswordEngine] owns ALL state and phases;
/// this widget only renders and forwards input. Letter placements,
/// selections and reveals all animate — results never pop instantly.
class GameScreen extends StatefulWidget {
  final CrosswordEngine engine;
  final PressAudio audio;
  final PressSettings settings;
  const GameScreen(
      {super.key,
      required this.engine,
      required this.audio,
      required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  CrosswordEngine get _e => widget.engine;
  PressSettings get _s => widget.settings;
  PressThemeDef get _t =>
      PressThemes.byId(_s.themeId, custom: _s.customTheme);
  CellLook get _look => CellLook.of(_t, _s.cellStyle);
  bool _reviewAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _e.onEvent = _onEngineEvent;
    _e.addListener(_onEngineChanged);
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngineChanged);
    _e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine on interruption; audio pause/resume is app-scoped.
    if (state == AppLifecycleState.paused) {
      _e.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      if (_e.paused && mounted) _showResumePrompt();
    }
  }

  void _showResumePrompt() {
    // Auto-resume would surprise; the pause overlay is already up.
    setState(() {});
  }

  void _onEngineEvent(XwEvent ev) {
    final a = widget.audio;
    switch (ev) {
      case XwEvent.typed:
        a.type();
      case XwEvent.erased:
        a.erase();
      case XwEvent.selected:
        a.select();
      case XwEvent.invalid:
        a.invalid();
      case XwEvent.checked:
        a.check();
      case XwEvent.revealed:
        a.reveal();
      case XwEvent.wordDone:
        a.wordDone();
      case XwEvent.won:
        a.win();
        _onWon();
      case XwEvent.lost:
        a.lose();
      case XwEvent.tick:
        a.tick();
    }
  }

  void _onEngineChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onWon() async {
    await _s.recordSolved(_e.title, _e.elapsed, _e.hintsUsed);
    // Sensible review moment: after a few solves, ask at most rarely.
    if (!_reviewAsked && _s.puzzlesSolved >= 3 && _s.puzzlesSolved % 3 == 0) {
      _reviewAsked = true;
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await Future.delayed(const Duration(milliseconds: 1200));
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  void _pause() {
    widget.audio.click();
    _e.setPaused(true);
  }

  void _resume() {
    widget.audio.click();
    _e.setPaused(false);
  }

  void _restart() {
    widget.audio.click();
    final puzzle = kCrosswordPuzzles.firstWhere(
      (p) => p['title'] == _e.title,
      orElse: () => kCrosswordPuzzles[0],
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          engine: CrosswordEngine(
            puzzle: puzzle,
            timed: _e.timed,
            difficulty: _e.difficulty,
          ),
          audio: widget.audio,
          settings: _s,
        ),
      ),
    );
  }

  void _quitToMenu() {
    widget.audio.click();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return DeskBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(t),
                  _clueBanner(t),
                  const SizedBox(height: 6),
                  Expanded(child: _grid(t)),
                  const SizedBox(height: 6),
                  _actionRow(t),
                  const SizedBox(height: 8),
                  _keyboard(t),
                  const SizedBox(height: 10),
                ],
              ),
              if (_e.paused && !_e.isDone) _pauseOverlayFull(t),
              if (_e.isDone) _doneOverlay(t),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- top bar
  Widget _topBar(PressThemeDef t) {
    final timeText = _e.timed
        ? _fmt(_e.remaining)
        : _fmt(_e.elapsed);
    final urgent = _e.timed && _e.remaining <= 30;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: _quitToMenu,
          ),
          Expanded(
            child: Column(
              children: [
                Text(_e.title, style: Press.display(20, theme: t)),
                Text(
                  '${_s.playerNames[0]}  •  ${_e.timed ? "⏱ timed" : "🍃 relaxed"}',
                  style: Press.label(11, theme: t),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                  color: urgent ? const Color(0xFFD94A56) : t.accent.withValues(alpha: 0.5)),
            ),
            child: Text(
              timeText,
              style: Press.ink(17,
                  theme: t,
                  color: urgent ? const Color(0xFFD94A56) : t.paper),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: t.accent.withValues(alpha: 0.5)),
            ),
            child: Text('${_e.score > 0 ? _e.score : _e.wordsSolved * 20} pts',
                style: Press.label(13, theme: t)),
          ),
          IconButton(
            icon: Icon(Icons.pause, color: t.accentLight),
            onPressed: _pause,
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------- clue bar
  Widget _clueBanner(PressThemeDef t) {
    final look = _look;
    final e = _e.sel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Container(
          key: ValueKey('clue${_e.selIndex}'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: look.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.accent.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: look.ink),
                onPressed: () => _e.nextWord(-1),
              ),
              Expanded(
                child: Text(
                  '${e.num}${e.dir == 'A' ? '→' : '↓'}  ${e.clue}',
                  style: Press.ink(15, theme: t, color: look.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: look.ink),
                onPressed: () => _e.nextWord(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ grid
  Widget _grid(PressThemeDef t) {
    final n = _e.n;
    return Center(
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
    );
  }

  Widget _cell(int r, int c, PressThemeDef t) {
    final look = _look;
    final sol = _e.solRows[r][c];
    if (sol == '.') {
      return Container(
        decoration: BoxDecoration(
          color: look.block.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(look.radius * 0.5),
        ),
      );
    }
    final selCells = _e.sel.cells;
    final inSel = selCells.any((p) => p.r == r && p.c == c);
    final cur = selCells[_e.cursor.clamp(0, selCells.length - 1)];
    final isCursor = inSel && cur.r == r && cur.c == c;
    final wrong = _e.wrongCells.contains('$r,$c');
    final revealed = _e.revealedCells.contains('$r,$c');
    int? num;
    for (final e in _e.entries) {
      if (e.r == r && e.c == c) {
        num = e.num;
        break;
      }
    }
    final letter = _e.letters[r][c];
    final bg = wrong
        ? const Color(0xFFD94A56)
        : isCursor
            ? t.cursor
            : inSel
                ? t.selected.withValues(alpha: 0.55)
                : look.paper;
    return GestureDetector(
      onTap: () => _e.tapCell(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(look.radius),
          border: Border.all(
            color: isCursor
                ? t.accentLight
                : wrong
                    ? const Color(0xFF8A1F28)
                    : t.ink.withValues(alpha: 0.28),
            width: isCursor ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: Offset(0, look.depth),
              blurRadius: look.depth * 1.6,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.18),
              offset: const Offset(0, -1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            if (num != null)
              Positioned(
                left: 3,
                top: 1,
                child: Text(
                  '$num',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: (wrong || isCursor)
                        ? Colors.white.withValues(alpha: 0.9)
                        : look.inkSoft,
                  ),
                ),
              ),
            Center(
              // Letter placement animates in with a stamp pop — never
              // appears instantly.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.4, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  letter,
                  key: ValueKey('L$r$c$letter'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: look.weight,
                    fontStyle:
                        revealed ? FontStyle.italic : FontStyle.normal,
                    color: (wrong || isCursor) ? Colors.white : look.ink,
                  ),
                ),
              ),
            ),
            if (revealed)
              Positioned(
                right: 3,
                bottom: 1,
                child: Icon(Icons.check,
                    size: 10,
                    color: (wrong || isCursor)
                        ? Colors.white70
                        : t.accentDark),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- action row
  Widget _actionRow(PressThemeDef t) {
    final locked = !_e.inputOpen;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: _actionBtn(t, 'Check', Icons.fact_check,
                  locked ? null : () => _e.check())),
          const SizedBox(width: 8),
          Expanded(
              child: _actionBtn(t, 'Reveal', Icons.lightbulb,
                  locked ? null : () => _e.reveal())),
          const SizedBox(width: 8),
          Expanded(
              child: _actionBtn(t, 'Clear', Icons.backspace,
                  locked ? null : () => _e.clearWord())),
        ],
      ),
    );
  }

  Widget _actionBtn(
      PressThemeDef t, String label, IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.deskMid, t.deskDeep],
            ),
            border: Border.all(color: t.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: t.accentLight, size: 18),
              const SizedBox(width: 6),
              Text(label, style: Press.label(14, theme: t)),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- keyboard
  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

  Widget _keyboard(PressThemeDef t) {
    final look = _look;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int ri = 0; ri < _rows.length; ri++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (ri == 2) const Spacer(flex: 1),
                  for (int i = 0; i < _rows[ri].length; i++)
                    Expanded(child: _key(_rows[ri][i], t, look)),
                  if (ri == 2)
                    Expanded(
                      child: _key('⌫', t, look, back: true),
                    ),
                  if (ri == 2) const Spacer(flex: 1),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(String ch, PressThemeDef t, CellLook look, {bool back = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () => back ? _e.backspace() : _e.typeLetter(ch),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: back ? t.accent.withValues(alpha: 0.35) : look.paper,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: t.accent.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 3),
                blurRadius: 5,
              ),
            ],
          ),
          child: back
              ? Icon(Icons.backspace_outlined, color: look.ink, size: 20)
              : Text(ch,
                  style: TextStyle(
                      color: look.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- pause overlay
  Widget _pauseOverlayFull(PressThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [t.deskMid, t.deskDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: Press.display(30, theme: t)),
              const SizedBox(height: 6),
              Text('Take a breath. The grid will wait.',
                  style: Press.body(14, theme: t,
                      color: t.paper.withValues(alpha: 0.7))),
              const SizedBox(height: 18),
              PressButton(
                  label: '▶  Resume',
                  onTap: _resume,
                  theme: t,
                  width: 210,
                  fontSize: 17),
              const SizedBox(height: 10),
              PressButton(
                  label: '↻  Restart',
                  onTap: _restart,
                  theme: t,
                  width: 210,
                  fontSize: 17,
                  primary: false),
              const SizedBox(height: 10),
              PressButton(
                  label: '☰  Menu',
                  onTap: _quitToMenu,
                  theme: t,
                  width: 210,
                  fontSize: 17,
                  primary: false),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- done overlay
  Widget _doneOverlay(PressThemeDef t) {
    final won = !_e.timedOut;
    final stars = _e.hintsUsed == 0
        ? 3
        : _e.hintsUsed <= 2
            ? 2
            : 1;
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  colors: [t.deskMid, t.deskDeep],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              border: Border.all(color: t.accent, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    offset: const Offset(0, 10),
                    blurRadius: 24),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(won ? '🎉' : '⏰',
                    style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  won ? 'Crossword cracked!' : "Time's up!",
                  style: Press.display(28, theme: t),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (won)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 3; i++)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300 + i * 250),
                          builder: (_, v, __) => Transform.scale(
                            scale: v,
                            child: Text(
                              i < stars ? '★' : '☆',
                              style: TextStyle(
                                fontSize: 34,
                                color: i < stars
                                    ? t.selected
                                    : t.paper.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Animated score count-up — never pops instantly.
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _e.score),
                  duration: const Duration(milliseconds: 1200),
                  builder: (_, v, __) => Text(
                    '$v pts',
                    style: Press.display(40, theme: t, color: t.accentLight),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  won
                      ? '${_e.title} complete • ${_fmt(_e.elapsed)} • ${_e.hintsUsed} reveal${_e.hintsUsed == 1 ? '' : 's'}'
                      : '${_e.title} — so close! Try relaxed mode for no timer.',
                  style: Press.body(13, theme: t,
                      color: t.paper.withValues(alpha: 0.75)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                PressButton(
                    label: won ? '▶  Next puzzle' : '↻  Try again',
                    onTap: won ? _nextPuzzle : _restart,
                    theme: t,
                    width: 220,
                    fontSize: 17),
                const SizedBox(height: 10),
                PressButton(
                    label: '↻  Replay',
                    onTap: _restart,
                    theme: t,
                    width: 220,
                    fontSize: 17,
                    primary: false),
                const SizedBox(height: 10),
                PressButton(
                    label: '☰  Menu',
                    onTap: _quitToMenu,
                    theme: t,
                    width: 220,
                    fontSize: 17,
                    primary: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nextPuzzle() {
    widget.audio.click();
    final idx = kCrosswordPuzzles.indexWhere((p) => p['title'] == _e.title);
    var next = (idx + 1) % kCrosswordPuzzles.length;
    // Skip PRO-locked puzzles for free players.
    for (int k = 0; k < kCrosswordPuzzles.length; k++) {
      final d = kCrosswordPuzzles[next]['difficulty'] as int;
      if (d <= 1 || _s.isPro) break;
      next = (next + 1) % kCrosswordPuzzles.length;
    }
    final puzzle = kCrosswordPuzzles[next];
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          engine: CrosswordEngine(
            puzzle: puzzle,
            timed: _e.timed,
            difficulty: puzzle['difficulty'] as int,
          ),
          audio: widget.audio,
          settings: _s,
        ),
      ),
    );
  }
}
