import 'dart:async';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Crossword engine: deterministic rules, ALL state/phases owned here.
// The UI only renders and forwards input. A watchdog recovers any phase
// found without a live timer, so stuck states are impossible by construction.
// ---------------------------------------------------------------------------

/// Turn phases owned entirely by the engine.
enum XwPhase {
  idle, // puzzle loaded, not started (unused after start())
  playing, // accepting input
  checking, // check flash in flight — input locked briefly
  revealing, // staged letter-by-letter reveal — input locked
  done, // puzzle solved or timed out
}

/// Events the UI/audio layer subscribes to via [onEvent].
enum XwEvent {
  typed,
  erased,
  selected,
  invalid,
  checked,
  revealed,
  wordDone,
  won,
  lost,
  tick,
}

class XwEntry {
  final String dir; // 'A' or 'D'
  final int num;
  final String word;
  final int r, c;
  final String clue;
  const XwEntry(this.dir, this.num, this.word, this.r, this.c, this.clue);

  List<XwPoint> get cells => [
        for (int i = 0; i < word.length; i++)
          dir == 'A' ? XwPoint(r, c + i) : XwPoint(r + i, c),
      ];
}

class XwPoint {
  final int r, c;
  const XwPoint(this.r, this.c);
  @override
  bool operator ==(Object other) =>
      other is XwPoint && other.r == r && other.c == c;
  @override
  int get hashCode => r * 97 + c;
  String get key => '$r,$c';
}

class CrosswordEngine extends ChangeNotifier {
  final String title;
  final int difficulty; // 0 mini, 1 classic, 2 expert
  final bool timed;

  late final int n;
  late final List<String> solRows;
  late final List<XwEntry> entries;
  late List<List<String>> letters; // user input

  int selIndex = 0;
  int cursor = 0;
  final Set<String> wrongCells = {}; // "r,c" flash set
  final Set<String> revealedCells = {}; // locked correct cells
  final Set<String> doneWords = {}; // entry indices fully correct

  int hintsUsed = 0;
  int checksUsed = 0;
  XwPhase phase = XwPhase.idle;
  bool paused = false;
  int elapsed = 0; // seconds since start
  int remaining = 0; // timed countdown
  bool timedOut = false;
  int score = 0;
  int wordsSolved = 0;

  /// Timed-mode limits per difficulty (seconds).
  static int timeLimitFor(int difficulty) =>
      const [300, 480, 720][difficulty.clamp(0, 2)];

  Timer? _tickTimer;
  Timer? _checkTimer;
  Timer? _revealTimer;
  Timer? _watchdog;
  final List<XwPoint> _revealQueue = [];
  bool _disposed = false;

  /// UI/audio hook. Never null-checked by engine logic itself.
  void Function(XwEvent)? onEvent;

  CrosswordEngine({
    required Map<String, Object?> puzzle,
    required this.timed,
    required this.difficulty,
  }) : title = puzzle['title'] as String {
    n = (puzzle['rows'] as List).length;
    solRows = List<String>.from(puzzle['rows'] as List);
    entries = [
      for (final e in (puzzle['entries'] as List))
        XwEntry(e['d'] as String, e['n'] as int, e['w'] as String,
            e['r'] as int, e['c'] as int, e['clue'] as String),
    ]..sort((a, b) => a.num.compareTo(b.num));
    letters = List.generate(n, (_) => List.filled(n, ''));
    remaining = timeLimitFor(difficulty);
    selIndex = entries.indexWhere((e) => e.dir == 'A');
    if (selIndex < 0) selIndex = 0;
    phase = XwPhase.playing;
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
    if (timed) _armTicker();
  }

  XwEntry get sel => entries[selIndex];
  bool get isDone => phase == XwPhase.done;
  bool get inputOpen => phase == XwPhase.playing && !paused && !isDone;
  bool get whiteComplete {
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_sol(r, c) != '.' && letters[r][c] != _sol(r, c)) return false;
      }
    }
    return true;
  }

  String _sol(int r, int c) => solRows[r][c];
  bool _white(int r, int c) => _sol(r, c) != '.';

  XwEntry? _entryAt(int r, int c, String dir) {
    for (final e in entries) {
      if (e.dir != dir) continue;
      if (e.cells.any((p) => p.r == r && p.c == c)) return e;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _tickTimer?.cancel();
    _checkTimer?.cancel();
    _revealTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ pause/life
  void setPaused(bool v) {
    if (paused == v || _disposed || isDone) return;
    paused = v;
    if (v) {
      _tickTimer?.cancel();
      _tickTimer = null;
      _checkTimer?.cancel();
      _checkTimer = null;
      _revealTimer?.cancel();
      _revealTimer = null;
    } else {
      _recover(); // re-arm whatever phase we are in
    }
    notifyListeners();
  }

  /// Watchdog: recover any phase found without a live timer.
  /// Makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || paused || isDone) return;
    switch (phase) {
      case XwPhase.playing:
        if (timed && _tickTimer == null) _armTicker();
      case XwPhase.checking:
        if (_checkTimer == null) _finishCheck();
      case XwPhase.revealing:
        if (_revealTimer == null) {
          if (_revealQueue.isEmpty) {
            phase = XwPhase.playing;
            if (timed) _armTicker();
            _afterReveal();
          } else {
            _scheduleRevealStep();
          }
        }
      case XwPhase.idle:
      case XwPhase.done:
        break;
    }
    notifyListeners();
  }

  void _armTicker() {
    if (_disposed || paused || isDone || _tickTimer != null) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || paused || isDone) {
        _tickTimer?.cancel();
        _tickTimer = null;
        return;
      }
      elapsed++;
      if (timed) {
        remaining--;
        if (remaining <= 10 && remaining > 0) onEvent?.call(XwEvent.tick);
        if (remaining <= 0) {
          _timeOut();
          return;
        }
      }
      notifyListeners();
    });
  }

  void _timeOut() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (isDone) return;
    timedOut = true;
    phase = XwPhase.done;
    score = _computeScore();
    onEvent?.call(XwEvent.lost);
    notifyListeners();
  }

  // ---------------------------------------------------------------- input
  /// Tap a cell: select its word; tap the same cell again flips across/down.
  void tapCell(int r, int c) {
    if (!inputOpen || !_white(r, c)) {
      if (_white(r, c)) onEvent?.call(XwEvent.invalid);
      return;
    }
    final a = _entryAt(r, c, 'A');
    final d = _entryAt(r, c, 'D');
    final curCell = sel.cells[cursor.clamp(0, sel.cells.length - 1)];
    if (curCell.r == r && curCell.c == c && a != null && d != null) {
      // Same cell tapped again: flip direction.
      final flipped = _entryAt(r, c, sel.dir == 'A' ? 'D' : 'A');
      if (flipped != null) {
        selIndex = entries.indexOf(flipped);
        cursor = flipped.cells.indexWhere((p) => p.r == r && p.c == c);
        if (cursor < 0) cursor = 0;
        onEvent?.call(XwEvent.selected);
      }
    } else {
      XwEntry? pick;
      if (a == sel || d == sel) {
        pick = (a == sel) ? a : d;
      } else {
        pick = (sel.dir == 'A' ? a : d) ?? a ?? d;
      }
      if (pick != null) {
        selIndex = entries.indexOf(pick);
        cursor = pick.cells.indexWhere((p) => p.r == r && p.c == c);
        if (cursor < 0) cursor = 0;
        onEvent?.call(XwEvent.selected);
      }
    }
    notifyListeners();
  }

  /// Move selection to the next/previous entry.
  void nextWord(int dirn) {
    if (!inputOpen) return;
    selIndex = (selIndex + dirn + entries.length) % entries.length;
    cursor = 0;
    onEvent?.call(XwEvent.selected);
    notifyListeners();
  }

  void selectEntry(int i) {
    if (!inputOpen || i < 0 || i >= entries.length) return;
    selIndex = i;
    cursor = 0;
    onEvent?.call(XwEvent.selected);
    notifyListeners();
  }

  /// Type a letter at the cursor. Revealed (locked) cells are skipped.
  void typeLetter(String ch) {
    if (!inputOpen) return;
    final cells = sel.cells;
    // advance past locked cells
    var ci = cursor;
    while (ci < cells.length &&
        revealedCells.contains(cells[ci].key)) {
      ci++;
    }
    if (ci >= cells.length) {
      onEvent?.call(XwEvent.invalid);
      return;
    }
    cursor = ci;
    final p = cells[cursor];
    letters[p.r][p.c] = ch;
    wrongCells.remove(p.key);
    onEvent?.call(XwEvent.typed);
    // advance cursor to next unlocked cell
    var ni = cursor + 1;
    while (ni < cells.length && revealedCells.contains(cells[ni].key)) {
      ni++;
    }
    cursor = ni.clamp(0, cells.length - 1);
    _checkWordDone(selIndex);
    _checkWin();
    notifyListeners();
  }

  void backspace() {
    if (!inputOpen) return;
    final cells = sel.cells;
    var ci = cursor.clamp(0, cells.length - 1);
    // If the cursor cell is empty or locked, step back to the nearest
    // editable cell that holds a letter.
    bool editable(int i) =>
        !revealedCells.contains(cells[i].key) &&
        letters[cells[i].r][cells[i].c].isNotEmpty;
    if (!editable(ci)) {
      var found = -1;
      for (int i = ci; i >= 0; i--) {
        if (editable(i)) {
          found = i;
          break;
        }
      }
      if (found < 0) {
        onEvent?.call(XwEvent.invalid);
        return;
      }
      ci = found;
    }
    final p = cells[ci];
    letters[p.r][p.c] = '';
    wrongCells.remove(p.key);
    cursor = ci;
    onEvent?.call(XwEvent.erased);
    notifyListeners();
  }

  /// Check the whole grid: flash wrong cells; win if perfect.
  void check() {
    if (!inputOpen) return;
    checksUsed++;
    phase = XwPhase.checking;
    wrongCells.clear();
    var bad = 0;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (!_white(r, c) || letters[r][c].isEmpty) continue;
        if (letters[r][c] != _sol(r, c)) {
          wrongCells.add('$r,$c');
          bad++;
        }
      }
    }
    onEvent?.call(XwEvent.checked);
    notifyListeners();
    _checkTimer?.cancel();
    if (bad == 0 && whiteComplete) {
      _win();
      return;
    }
    _checkTimer = Timer(const Duration(milliseconds: 1400), () {
      _checkTimer = null;
      _finishCheck();
    });
  }

  void _finishCheck() {
    if (_disposed || isDone) return;
    wrongCells.clear();
    if (phase == XwPhase.checking) phase = XwPhase.playing;
    _checkWin();
    notifyListeners();
  }

  /// Reveal the selected word letter-by-letter (staged animation).
  void reveal() {
    if (!inputOpen) return;
    final cells = sel.cells;
    _revealQueue
      ..clear()
      ..addAll([for (final p in cells) if (!revealedCells.contains(p.key)) p]);
    if (_revealQueue.isEmpty) {
      onEvent?.call(XwEvent.invalid);
      return;
    }
    hintsUsed++;
    phase = XwPhase.revealing;
    onEvent?.call(XwEvent.revealed);
    notifyListeners();
    _scheduleRevealStep();
  }

  void _scheduleRevealStep() {
    if (_disposed || paused || isDone) return;
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(milliseconds: 130), () {
      _revealTimer = null;
      if (_disposed || paused || isDone) return;
      if (_revealQueue.isEmpty) {
        phase = XwPhase.playing;
        if (timed) _armTicker();
        _afterReveal();
        notifyListeners();
        return;
      }
      final p = _revealQueue.removeAt(0);
      letters[p.r][p.c] = _sol(p.r, p.c);
      revealedCells.add(p.key);
      wrongCells.remove(p.key);
      notifyListeners();
      _scheduleRevealStep();
    });
  }

  void _afterReveal() {
    _checkWordDone(selIndex);
    _checkWin();
  }

  /// Clear the selected word's editable cells (revealed cells stay locked).
  void clearWord() {
    if (!inputOpen) return;
    var cleared = false;
    for (final p in sel.cells) {
      if (!revealedCells.contains(p.key) && letters[p.r][p.c].isNotEmpty) {
        letters[p.r][p.c] = '';
        wrongCells.remove(p.key);
        cleared = true;
      }
    }
    cursor = 0;
    if (cleared) {
      onEvent?.call(XwEvent.erased);
    } else {
      onEvent?.call(XwEvent.invalid);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- rules
  void _checkWordDone(int ei) {
    final key = '$ei';
    if (doneWords.contains(key)) return;
    final e = entries[ei];
    for (final p in e.cells) {
      if (letters[p.r][p.c] != _sol(p.r, p.c)) return;
    }
    doneWords.add(key);
    wordsSolved++;
    onEvent?.call(XwEvent.wordDone);
  }

  void _checkWin() {
    if (isDone || !whiteComplete) return;
    _win();
  }

  void _win() {
    if (isDone) return;
    _tickTimer?.cancel();
    _tickTimer = null;
    phase = XwPhase.done;
    score = _computeScore();
    onEvent?.call(XwEvent.won);
    notifyListeners();
  }

  int _computeScore() {
    final base = entries.length * 20;
    final timeBonus =
        timed ? remaining * 2 : (300 - elapsed).clamp(0, 300);
    final s = base + timeBonus - hintsUsed * 10 - checksUsed * 2;
    return s.clamp(10, 9999);
  }
}
