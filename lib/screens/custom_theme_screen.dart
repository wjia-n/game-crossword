import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/morning_press.dart';
import '../theme/press_themes.dart';

/// PRO-only custom theme creator: design your own press edition.
/// Colors persist via [PressSettings.customColors].
class CustomThemeScreen extends StatefulWidget {
  final PressAudio audio;
  final PressSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  PressThemeDef get _t => PressThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  static const _rows = [
    ('deskDark', 'Desk shadow'),
    ('deskMid', 'Desk leather'),
    ('deskDeep', 'Desk depth'),
    ('paper', 'Paper'),
    ('paperDeep', 'Paper shade'),
    ('ink', 'Ink'),
    ('inkSoft', 'Soft ink'),
    ('accent', 'Accent'),
    ('accentLight', 'Accent light'),
    ('accentDark', 'Accent dark'),
    ('selected', 'Word highlight'),
    ('cursor', 'Cursor'),
  ];

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
          title: Text('My Edition', style: Press.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                widget.audio.click();
                s.resetCustomColors();
              },
              child: Text('Reset', style: Press.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) {
              final preview =
                  PressThemes.byId('custom', custom: s.customTheme);
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview strip.
                    Container(
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [preview.paper, preview.deskMid],
                        ),
                        border:
                            Border.all(color: preview.accent, width: 2.5),
                      ),
                      child: Center(
                        child: Text('Aa Crossword',
                            style: Press.display(26,
                                theme: preview, color: preview.ink)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap a swatch, then pick a color. Applies instantly.',
                      style: Press.body(13,
                          theme: t, color: t.paper.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 12),
                    for (final row in _rows)
                      _colorRow(t, s, row.$1, row.$2),
                    const SizedBox(height: 16),
                    Center(
                      child: PressButton(
                        label: s.themeId == 'custom'
                            ? '✓  Using My Edition'
                            : 'Use My Edition',
                        width: 240,
                        fontSize: 17,
                        theme: t,
                        onTap: s.themeId == 'custom'
                            ? null
                            : () {
                                widget.audio.click();
                                s.setTheme('custom');
                              },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _colorRow(
      PressThemeDef t, PressSettings s, String key, String label) {
    final color = Color(s.customColors[key] ?? 0xFF000000);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.deskDeep.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Press.body(15, theme: t))),
          GestureDetector(
            onTap: () {
              widget.audio.click();
              _pickColor(t, s, key, label, color);
            },
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color,
                border: Border.all(color: t.accentLight, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickColor(PressThemeDef t, PressSettings s, String key, String label,
      Color current) {
    var hsv = HSVColor.fromColor(current);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [t.deskMid, t.deskDeep],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(color: t.accent, width: 3),
          ),
          child: StatefulBuilder(
            builder: (ctx, setDialog) {
              Color picked() => hsv.toColor();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Press.display(20, theme: t)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (_, constraints) => GestureDetector(
                      onPanUpdate: (d) => setDialog(() {
                        hsv = hsv.withHue(
                            (d.localPosition.dx / constraints.maxWidth)
                                    .clamp(0.0, 1.0) *
                                360);
                      }),
                      onTapDown: (d) => setDialog(() {
                        hsv = hsv.withHue(
                            (d.localPosition.dx / constraints.maxWidth)
                                    .clamp(0.0, 1.0) *
                                360);
                      }),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              for (int h = 0; h <= 12; h++)
                                HSVColor.fromAHSV(1, h * 30.0, 0.75, 0.85)
                                    .toColor(),
                            ],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Dark', style: Press.body(12, theme: t)),
                      Expanded(
                        child: Slider(
                          value: hsv.value,
                          onChanged: (v) =>
                              setDialog(() => hsv = hsv.withValue(v)),
                          activeColor: t.accent,
                          inactiveColor: t.deskDeep,
                        ),
                      ),
                      Text('Light', style: Press.body(12, theme: t)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Grey', style: Press.body(12, theme: t)),
                      Expanded(
                        child: Slider(
                          value: hsv.saturation,
                          onChanged: (v) =>
                              setDialog(() => hsv = hsv.withSaturation(v)),
                          activeColor: t.accent,
                          inactiveColor: t.deskDeep,
                        ),
                      ),
                      Text('Vivid', style: Press.body(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: picked(),
                      border: Border.all(color: t.accentLight, width: 2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressButton(
                    label: 'Use this color',
                    width: 200,
                    fontSize: 16,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      s.setCustomColor(key, picked().toARGB32());
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
