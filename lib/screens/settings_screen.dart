import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/morning_press.dart';
import '../theme/press_themes.dart';

/// Settings: music/SFX toggles, volume, stats, reset.
class SettingsScreen extends StatefulWidget {
  final PressAudio audio;
  final PressSettings settings;
  const SettingsScreen({super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PressThemeDef get _t => PressThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return DeskBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Press.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audio', style: Press.display(20, theme: t)),
                  const SizedBox(height: 8),
                  SettingRow(
                    label: '🎵 Music',
                    theme: t,
                    control: PressToggle(
                      value: s.musicOn,
                      theme: t,
                      onChanged: (v) async {
                        widget.audio.click();
                        await s.setMusic(v);
                        _applyAudio();
                        if (v) widget.audio.startMenuMusic();
                      },
                    ),
                  ),
                  SettingRow(
                    label: '🔔 Sound effects',
                    theme: t,
                    control: PressToggle(
                      value: s.sfxOn,
                      theme: t,
                      onChanged: (v) async {
                        await s.setSfx(v);
                        _applyAudio();
                        widget.audio.click();
                      },
                    ),
                  ),
                  SettingRow(
                    label: '🔊 Volume',
                    theme: t,
                    control: SizedBox(
                      width: 150,
                      child: NibSlider(
                        value: s.volume,
                        theme: t,
                        onChanged: (v) async {
                          await s.setVolume(v);
                          _applyAudio();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Your Record', style: Press.display(20, theme: t)),
                  const SizedBox(height: 8),
                  PaperCard(
                    theme: t,
                    child: Column(
                      children: [
                        _statRow(t, 'Puzzles solved', '${s.puzzlesSolved}'),
                        _statRow(t, 'Reveals used', '${s.hintsUsed}'),
                        if (s.bestTimes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          for (final e in s.bestTimes.entries)
                            _statRow(t, '⏱ ${e.key}',
                                '${(e.value ~/ 60).toString().padLeft(2, '0')}:${(e.value % 60).toString().padLeft(2, '0')}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Crossword — The Morning Press Edition\nCredits: WAJIHA',
                      style: Press.body(12, theme: t,
                          color: t.paper.withValues(alpha: 0.55)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(PressThemeDef t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Press.body(14, theme: t))),
          Text(value, style: Press.label(14, theme: t)),
        ],
      ),
    );
  }
}
