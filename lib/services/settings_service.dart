import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/press_themes.dart';

/// Persisted settings + stats for Crossword. Survives app restarts.
///
/// Stores: audio toggles, player name, theme/cell-style choices (incl.
/// custom theme colors), difficulty tier, timed/relaxed mode, Pro unlock
/// state, and lifetime stats.
class PressSettings extends ChangeNotifier {
  static const _kMusic = 'xw_music_on';
  static const _kSfx = 'xw_sfx_on';
  static const _kVolume = 'xw_volume';
  static const _kNames = 'xw_player_names'; // legacy unordered StringSet key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'xw_player_names_json';
  static const _kTheme = 'xw_theme_id';
  static const _kStyle = 'xw_cell_style';
  static const _kDifficulty = 'xw_difficulty'; // 0 mini, 1 classic, 2 expert
  static const _kTimed = 'xw_timed_mode';
  static const _kSolved = 'xw_puzzles_solved';
  static const _kHints = 'xw_hints_used';
  static const _kBestTimes = 'xw_best_times_json'; // {puzzleTitle: seconds}
  static const _kIsPro = 'xw_is_pro';
  static const _kCustomPrefix = 'xw_custom_';

  static const defaultNames = ['Word Sleuth'];

  /// Encode player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == defaultNames.length) {
        return [for (int i = 0; i < defaultNames.length; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'morning';
  int cellStyle = 0;
  int difficulty = 0;
  bool timedMode = false;
  int puzzlesSolved = 0;
  int hintsUsed = 0;
  Map<String, int> bestTimes = {};
  bool isPro = true; // everything unlocked — no Pro version

  /// Custom theme colors (ARGB ints). Defaults mirror Morning Edition.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'deskDark': 0xFF2B1D16,
    'deskMid': 0xFF3E2A1E,
    'deskDeep': 0xFF1A110B,
    'paper': 0xFFF5EDD8,
    'paperDeep': 0xFFE4D5B4,
    'ink': 0xFF2A2118,
    'inkSoft': 0xFF7A6A52,
    'accent': 0xFFA31621,
    'accentLight': 0xFFD94A56,
    'accentDark': 0xFF6E0E16,
    'selected': 0xFFE8B93C,
    'cursor': 0xFFA31621,
  };

  /// Builds the user-designed custom theme from stored colors.
  PressThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return PressThemeDef(
      id: 'custom',
      name: 'My Edition',
      deskDark: c('deskDark'),
      deskMid: c('deskMid'),
      deskDeep: c('deskDeep'),
      paper: c('paper'),
      paperDeep: c('paperDeep'),
      ink: c('ink'),
      inkSoft: c('inkSoft'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      selected: c('selected'),
      cursor: c('cursor'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == defaultNames.length)
          ? [for (int i = 0; i < defaultNames.length; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'morning';
    cellStyle = (p.getInt(_kStyle) ?? 0).clamp(0, CellStyles.names.length - 1);
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    timedMode = p.getBool(_kTimed) ?? false;
    puzzlesSolved = p.getInt(_kSolved) ?? 0;
    hintsUsed = p.getInt(_kHints) ?? 0;
    try {
      final raw = p.getString(_kBestTimes);
      if (raw != null) {
        final d = jsonDecode(raw);
        if (d is Map) {
          bestTimes = {
            for (final e in d.entries)
              if (e.key is String && e.value is int) e.key as String: e.value as int
          };
        }
      }
    } catch (_) {}
    isPro = true; // everything unlocked
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kStyle, cellStyle);
    await p.setInt(_kDifficulty, difficulty);
    await p.setBool(_kTimed, timedMode);
    await p.setInt(_kSolved, puzzlesSolved);
    await p.setInt(_kHints, hintsUsed);
    await p.setString(_kBestTimes, jsonEncode(bestTimes));
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || PressThemes.isProTheme(themeId)) {
      themeId = 'morning';
      changed = true;
    }
    if (CellStyles.isPro(cellStyle)) {
      cellStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index >= defaultNames.length) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows lock).
    if (!isPro && (id == 'custom' || PressThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setCellStyle(int v) async {
    v = v.clamp(0, CellStyles.names.length - 1);
    if (!isPro && CellStyles.isPro(v)) return;
    cellStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    // Expert puzzles are a Pro feature.
    if (!isPro && v > 1) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setTimedMode(bool v) async {
    timedMode = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished puzzle.
  Future<void> recordSolved(String title, int seconds, int hints) async {
    puzzlesSolved++;
    hintsUsed += hints;
    final prev = bestTimes[title];
    if (prev == null || seconds < prev) bestTimes[title] = seconds;
    notifyListeners();
    await _save();
  }
}
