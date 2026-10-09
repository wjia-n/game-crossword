import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/crossword_engine.dart';
import '../puzzles.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/morning_press.dart';
import '../theme/press_themes.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: puzzle picker by difficulty, name, timed mode, themes,
/// cell styles, Pro, share/rate/settings/how-to.
class MenuScreen extends StatefulWidget {
  final PressAudio audio;
  final PressSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final StoreService _store;
  final _nameCtrl = TextEditingController();
  int _puzzleIdx = 0;

  PressSettings get _s => widget.settings;
  PressThemeDef get _t =>
      PressThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    _store = StoreService();
    _store.init();
    _store.proPurchased.addListener(_onPro);
    _store.lastThanks.addListener(_onThanks);
    _nameCtrl.text = _s.playerNames[0];
    _pickFirstUnlocked();
  }

  void _pickFirstUnlocked() {
    for (int i = 0; i < kCrosswordPuzzles.length; i++) {
      final d = kCrosswordPuzzles[i]['difficulty'] as int;
      if (d <= 1 || _s.isPro) {
        _puzzleIdx = i;
        return;
      }
    }
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      _s.setPro(true);
      widget.audio.win();
      _store.proPurchased.value = false;
      setState(() {});
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Press.body(15, theme: _t)),
        backgroundColor: _t.deskDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    final puzzle = kCrosswordPuzzles[_puzzleIdx];
    final difficulty = puzzle['difficulty'] as int;
    if (difficulty > 1 && !_s.isPro) {
      widget.audio.invalid();
      _goPro();
      return;
    }
    widget.audio.gameStart();
    final engine = CrosswordEngine(
      puzzle: puzzle,
      timed: _s.timedMode,
      difficulty: difficulty,
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) {
        widget.audio.startMenuMusic();
        setState(() {});
      }
    });
  }

  void _goPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return DeskBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/crossword_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('Crossword', style: Press.display(46, theme: t)),
                  Text(
                    'THE MORNING PRESS EDITION',
                    style: Press.label(12, theme: t),
                  ),
                  const SizedBox(height: 22),
                  PressButton(
                      label: '▶  Play', onTap: _play, theme: t, width: 260),
                  if (!_s.isPro) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _goPro,
                      child: Container(
                        width: 260,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [t.accentLight, t.accent, t.accentDark],
                          ),
                          border: Border.all(color: t.paper, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(0, 5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text('✦  Go PRO',
                            style: Press.display(18, theme: t, color: t.paper)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _PuzzleCard(
                      theme: t,
                      state: this,
                      onPuzzle: (i) => setState(() => _puzzleIdx = i)),
                  const SizedBox(height: 14),
                  _NameCard(theme: t, state: this),
                  const SizedBox(height: 14),
                  _ThemeCard(
                      theme: t,
                      state: this,
                      onRefresh: () => setState(() {})),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t, state: this),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          // ignore: deprecated_member_use
                          await Share.share(
                              'Play Crossword with me! https://play.google.com/store/apps/details?id=com.gameswajiha.crossword');
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.puzzlesSolved > 0)
                    Text(
                      'Solved: ${_s.puzzlesSolved}   •   Hints: ${_s.hintsUsed}',
                      style: Press.label(12, theme: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Press.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, PressThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [t.deskMid, t.deskDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: Press.display(24, theme: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• Pick a puzzle: Mini (easy), Classic (medium), or Expert (hard, PRO).',
                  '• Tap a square to select its word — tap the same square again to flip across ↕ down.',
                  '• Type letters with the A–Z keyboard; ⌫ erases.',
                  '• Timed mode: beat the clock for bonus points. Relaxed: no timer, just vibes.',
                  '• Use Check to spot mistakes and Reveal when truly stuck (reveals count as hints).',
                  '• Fill every square correctly to win. Wrong letters flash red — fix them and keep going!',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line, style: Press.body(14, theme: t)),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: PressButton(
                    label: 'Got it!',
                    width: 160,
                    fontSize: 16,
                    theme: t,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Puzzle picker grouped by difficulty tier.
class _PuzzleCard extends StatelessWidget {
  final PressThemeDef theme;
  final _MenuScreenState state;
  final ValueChanged<int> onPuzzle;
  const _PuzzleCard(
      {required this.theme, required this.state, required this.onPuzzle});

  static const tierNames = ['MINI — easy', 'CLASSIC — medium', 'EXPERT — hard'];

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = state._s;
    return PaperCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Puzzles", style: Press.display(20, theme: t)),
          const SizedBox(height: 4),
          Text('Pick your crossword. Expert needs PRO.',
              style: Press.body(13, theme: t, color: t.paper.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          for (int tier = 0; tier < 3; tier++) ...[
            Text(tierNames[tier], style: Press.label(12, theme: t)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < kCrosswordPuzzles.length; i++)
                  if ((kCrosswordPuzzles[i]['difficulty'] as int) == tier)
                    _puzzleChip(t, s, i),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SettingRow(
            label: '⏱ Timed mode',
            theme: t,
            control: PressToggle(
              value: s.timedMode,
              theme: t,
              onChanged: (v) {
                state.widget.audio.click();
                s.setTimedMode(v);
              },
            ),
          ),
          Text(
            s.timedMode
                ? 'Beat the clock — leftover seconds become bonus points.'
                : 'Relaxed mode — no timer, solve at your own pace.',
            style: Press.body(12, theme: t, color: t.paper.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }

  Widget _puzzleChip(PressThemeDef t, PressSettings s, int i) {
    final title = kCrosswordPuzzles[i]['title'] as String;
    final locked = (kCrosswordPuzzles[i]['difficulty'] as int) > 1 && !s.isPro;
    final selected = state._puzzleIdx == i;
    return GestureDetector(
      onTap: () {
        if (locked) {
          state.widget.audio.invalid();
          state._goPro();
          return;
        }
        state.widget.audio.click();
        onPuzzle(i);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? t.accent
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected ? t.accentLight : t.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          locked ? '🔒 $title' : title,
          style: Press.label(13, theme: t,
              color: selected ? t.paper : t.paper.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _NameCard extends StatelessWidget {
  final PressThemeDef theme;
  final _MenuScreenState state;
  const _NameCard({required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return PaperCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Byline', style: Press.display(20, theme: t)),
          const SizedBox(height: 4),
          Text('The name on your solved puzzles.',
              style: Press.body(13, theme: t, color: t.paper.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(color: t.accent.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: state._nameCtrl,
              style: Press.body(16, theme: t),
              maxLength: 16,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Word Sleuth',
                hintStyle: Press.body(16, theme: t,
                    color: t.paper.withValues(alpha: 0.35)),
              ),
              onSubmitted: (v) {
                state.widget.audio.click();
                state._s.setPlayerName(0, v);
                FocusScope.of(context).unfocus();
              },
              // Save on every keystroke so the name never gets lost.
              onChanged: (v) => state._s.setPlayerName(0, v),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Theme picker: 22 press themes as swatches, PRO ones locked.
class _ThemeCard extends StatelessWidget {
  final PressThemeDef theme;
  final _MenuScreenState state;
  final VoidCallback onRefresh;
  const _ThemeCard(
      {required this.theme, required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = state._s;
    return PaperCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Press Themes', style: Press.display(20, theme: t))),
              GestureDetector(
                onTap: () async {
                  state.widget.audio.click();
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: state.widget.audio,
                      settings: s,
                    ),
                  ));
                  if (context.mounted) onRefresh();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.accent, width: 1.5),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    s.isPro ? '🎨 My Edition' : '🎨 🔒',
                    style: Press.label(12, theme: t),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('22 editions. First 4 free, the rest PRO.',
              style: Press.body(13, theme: t, color: t.paper.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: PressThemes.all.length,
            itemBuilder: (_, i) {
              final th = PressThemes.all[i];
              final locked = PressThemes.isProTheme(th.id) && !s.isPro;
              final selected = s.themeId == th.id;
              return GestureDetector(
                onTap: () {
                  if (locked) {
                    state.widget.audio.invalid();
                    state._goPro();
                    return;
                  }
                  state.widget.audio.click();
                  s.setTheme(th.id);
                },
                child: Column(
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [th.paper, th.deskMid],
                        ),
                        border: Border.all(
                          color: selected ? th.accentLight : th.accent.withValues(alpha: 0.4),
                          width: selected ? 3 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          locked ? '🔒' : (selected ? '✓' : 'Aa'),
                          style: TextStyle(
                            color: th.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      th.name.split(' ').first,
                      style: Press.body(10, theme: t,
                          color: t.paper.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Cell style picker: 8 styles, first 3 free.
class _StyleCard extends StatelessWidget {
  final PressThemeDef theme;
  final _MenuScreenState state;
  const _StyleCard({required this.theme, required this.state});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final s = state._s;
    return PaperCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cell Styles', style: Press.display(20, theme: t)),
          const SizedBox(height: 4),
          Text('How your puzzle squares look. First 3 free, the rest PRO.',
              style: Press.body(13, theme: t, color: t.paper.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < CellStyles.names.length; i++)
                _styleChip(t, s, i),
            ],
          ),
          const SizedBox(height: 6),
          Text(CellStyles.descriptions[s.cellStyle],
              style: Press.body(12, theme: t, color: t.paper.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _styleChip(PressThemeDef t, PressSettings s, int i) {
    final locked = CellStyles.isPro(i) && !s.isPro;
    final selected = s.cellStyle == i;
    return GestureDetector(
      onTap: () {
        if (locked) {
          state.widget.audio.invalid();
          state._goPro();
          return;
        }
        state.widget.audio.click();
        s.setCellStyle(i);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? t.accent : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected ? t.accentLight : t.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          locked ? '🔒 ${CellStyles.names[i]}' : CellStyles.names[i],
          style: Press.label(13, theme: t,
              color: selected ? t.paper : t.paper.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _SupportCard extends StatelessWidget {
  final PressThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return PaperCard(
      theme: t,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support the Press', style: Press.display(18, theme: t)),
                const SizedBox(height: 4),
                Text('PRO unlocks everything. Tips keep the ink flowing.',
                    style: Press.body(12, theme: t,
                        color: t.paper.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              final st = context.findAncestorStateOfType<_MenuScreenState>();
              st?.widget.audio.click();
              st?._goPro();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.accent, width: 2),
                color: t.accent.withValues(alpha: 0.2),
              ),
              child: Text('✦ PRO', style: Press.label(14, theme: t)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final PressThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
            child: Icon(icon, color: t.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Press.label(11, theme: t)),
        ],
      ),
    );
  }
}
