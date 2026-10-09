import 'package:flutter/material.dart';
import 'press_themes.dart';

/// The Morning Press design system for Crossword.
/// Newsroom materiality: leather desk, aged paper, printer's ink,
/// brass and oxblood trim. Serif headlines, readable body.
/// No neon, no cyberpunk, no generic Material look.
class Press {
  static const displayFont = 'serif';

  static TextStyle display(double size, {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.paper ?? const Color(0xFFF5EDD8),
        letterSpacing: 1.1,
        shadows: const [
          Shadow(color: Color(0x99000000), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.paper ?? const Color(0xFFF5EDD8),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFD94A56),
        letterSpacing: 0.8,
      );

  static TextStyle ink(double size, {Color? color, PressThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.ink ?? const Color(0xFF2A2118),
      );

  static ThemeData theme([PressThemeDef? t]) {
    t ??= PressThemes.byId('morning');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.deskDark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.accent,
        onPrimary: t.paper,
        secondary: t.accentLight,
        onSecondary: t.deskDeep,
        surface: t.deskMid,
        onSurface: t.paper,
        error: t.accent,
        onError: t.paper,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.deskMid),
    );
  }
}

/// Leather desk backdrop with a warm vignette, theme-aware.
class DeskBackdrop extends StatelessWidget {
  final Widget child;
  final PressThemeDef? theme;
  const DeskBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('morning');
    return Container(
      decoration: BoxDecoration(color: t.deskDark),
      child: CustomPaint(
        painter: _LeatherPainter(t),
        child: child,
      ),
    );
  }
}

class _LeatherPainter extends CustomPainter {
  final PressThemeDef t;
  _LeatherPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.15,
      colors: [
        t.deskMid.withValues(alpha: 0.55),
        t.deskDark.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
    final grain = Paint()
      ..color = t.deskDeep.withValues(alpha: 0.18)
      ..strokeWidth = 2.5;
    for (int i = 0; i < 14; i++) {
      final x = size.width * (i + 0.5) / 14;
      final wobble = (i % 3 - 1) * 8.0;
      canvas.drawLine(
        Offset(x + wobble, 0),
        Offset(x - wobble, size.height),
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky press-plate button — looks physically pressable.
class PressButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final PressThemeDef? theme;
  final bool primary;

  const PressButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 240,
    this.fontSize = 19,
    this.theme,
    this.primary = true,
  });

  @override
  State<PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<PressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme ?? PressThemes.byId('morning');
    final enabled = widget.onTap != null;
    final base = widget.primary ? t.accent : t.deskMid;
    final deep = widget.primary ? t.accentDark : t.deskDeep;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [t.accentLight.withValues(alpha: 0.55), base, deep]
                : [t.deskDeep.withValues(alpha: 0.7), t.deskDeep.withValues(alpha: 0.5)],
          ),
          border: Border.all(color: t.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: t.accentLight.withValues(alpha: _pressed ? 0.05 : 0.22),
              offset: const Offset(0, -2),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Press.display(
            widget.fontSize,
            theme: t,
            color: enabled ? t.paper : t.paper.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

/// An engraved plate for titles.
class InkPlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final PressThemeDef? theme;
  const InkPlaque({super.key, required this.title, this.subtitle, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('morning');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.deskDeep, t.deskDark],
        ),
        border: Border.all(color: t.accent, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 6),
              blurRadius: 12),
          BoxShadow(
              color: t.accentLight.withValues(alpha: 0.7),
              offset: const Offset(0, -1),
              blurRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Press.display(30, theme: t), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: Press.body(14, theme: t, color: t.paper.withValues(alpha: 0.75)),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// A paper card panel for grouping menu content.
class PaperCard extends StatelessWidget {
  final Widget child;
  final PressThemeDef? theme;
  final EdgeInsetsGeometry padding;
  const PaperCard({
    super.key,
    required this.child,
    this.theme,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('morning');
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.deskMid.withValues(alpha: 0.9),
            t.deskDeep.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: t.accent.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A brass lever toggle for settings.
class PressToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final PressThemeDef? theme;
  const PressToggle({super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('morning');
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? t.accentDark : t.deskDeep,
          border: Border.all(color: t.accent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.accentLight, t.accent, t.accentDark],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A nib volume slider on a brass rail.
class NibSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final PressThemeDef? theme;
  const NibSlider({super.key, required this.value, required this.onChanged, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('morning');
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.deskDeep,
        thumbShape: _NibThumb(t),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _NibThumb extends SliderComponentShape {
  final PressThemeDef t;
  const _NibThumb(this.t);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2), 12, Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [t.accentLight, t.accent, t.accentDark],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final PressThemeDef? theme;
  const SettingRow({super.key, required this.label, required this.control, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? PressThemes.byId('morning');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: t.deskDeep.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Press.body(16, theme: t))),
          control,
        ],
      ),
    );
  }
}
