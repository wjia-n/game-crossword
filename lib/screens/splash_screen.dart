import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/morning_press.dart';
import '../theme/press_themes.dart';
import 'menu_screen.dart';

/// Launch splash: WAJIHA company splash → game splash
/// (logo + name + animated loading line + Credits: WAJIHA).
class SplashScreen extends StatefulWidget {
  final PressAudio audio;
  final PressSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyPhase = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the company splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyPhase = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PressThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF14100B),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _companyPhase
            ? _CompanySplash(key: const ValueKey('co'), theme: theme)
            : _GameSplash(
                key: const ValueKey('game'), theme: theme, loader: _loader),
      ),
    );
  }
}

/// Company splash: the official WAJIHA logo, shown untouched first.
class _CompanySplash extends StatelessWidget {
  final PressThemeDef theme;
  const _CompanySplash({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Image.asset(
                  'assets/wajiha_logo.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'WAJIHA',
              style: Press.display(30, theme: theme,
                  color: const Color(0xFF8FB3FF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final PressThemeDef theme;
  final AnimationController loader;
  const _GameSplash(
      {super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return DeskBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/crossword_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Crossword', style: Press.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'THE MORNING PRESS EDITION',
              style: Press.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Setting the type…' : 'Ready!',
                      style: Press.body(13,
                          theme: theme,
                          color: theme.paper.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Press.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
