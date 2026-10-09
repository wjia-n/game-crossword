import 'package:flutter/material.dart';

/// Theme + cell-style catalogs for Crossword: The Morning Press edition.
///
/// Every theme stays inside the newsroom material world — aged paper,
/// leather desks, printer's ink, brass and oxblood trim. The variety comes
/// from different papers, desk leathers, ink tones and accent metals.
class PressThemeDef {
  final String id;
  final String name;
  final Color deskDark;
  final Color deskMid;
  final Color deskDeep;
  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color inkSoft;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final Color selected;
  final Color cursor;

  const PressThemeDef({
    required this.id,
    required this.name,
    required this.deskDark,
    required this.deskMid,
    required this.deskDeep,
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.selected,
    required this.cursor,
  });
}

class PressThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'morning',
    'sunday',
    'broadsheet',
    'leather',
  ];

  static const List<PressThemeDef> all = [
    PressThemeDef(
      id: 'morning',
      name: 'Morning Edition',
      deskDark: Color(0xFF2B1D16),
      deskMid: Color(0xFF3E2A1E),
      deskDeep: Color(0xFF1A110B),
      paper: Color(0xFFF5EDD8),
      paperDeep: Color(0xFFE4D5B4),
      ink: Color(0xFF2A2118),
      inkSoft: Color(0xFF7A6A52),
      accent: Color(0xFFA31621),
      accentLight: Color(0xFFD94A56),
      accentDark: Color(0xFF6E0E16),
      selected: Color(0xFFE8B93C),
      cursor: Color(0xFFA31621),
    ),
    PressThemeDef(
      id: 'sunday',
      name: 'Sunday Press',
      deskDark: Color(0xFF243024),
      deskMid: Color(0xFF35432F),
      deskDeep: Color(0xFF141B12),
      paper: Color(0xFFF8F2E2),
      paperDeep: Color(0xFFE8DCC0),
      ink: Color(0xFF232A1E),
      inkSoft: Color(0xFF6E7458),
      accent: Color(0xFF8C6A2F),
      accentLight: Color(0xFFC49A5A),
      accentDark: Color(0xFF5E421E),
      selected: Color(0xFFC9A227),
      cursor: Color(0xFF8C6A2F),
    ),
    PressThemeDef(
      id: 'broadsheet',
      name: 'Vintage Broadsheet',
      deskDark: Color(0xFF1E2430),
      deskMid: Color(0xFF2E3A4C),
      deskDeep: Color(0xFF10141C),
      paper: Color(0xFFEFE8D2),
      paperDeep: Color(0xFFD9CBA6),
      ink: Color(0xFF1C2230),
      inkSoft: Color(0xFF626C80),
      accent: Color(0xFFB08D3E),
      accentLight: Color(0xFFDFC084),
      accentDark: Color(0xFF7A6128),
      selected: Color(0xFF7FA8C9),
      cursor: Color(0xFFB08D3E),
    ),
    PressThemeDef(
      id: 'leather',
      name: 'Leather Desk',
      deskDark: Color(0xFF3A2318),
      deskMid: Color(0xFF52301F),
      deskDeep: Color(0xFF20130C),
      paper: Color(0xFFF1E6CC),
      paperDeep: Color(0xFFDDC89E),
      ink: Color(0xFF2E1F14),
      inkSoft: Color(0xFF7E6A52),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      selected: Color(0xFFD9A441),
      cursor: Color(0xFFC9A227),
    ),
    PressThemeDef(
      id: 'midnight',
      name: 'Midnight Oil',
      deskDark: Color(0xFF14161E),
      deskMid: Color(0xFF22262F),
      deskDeep: Color(0xFF0A0B0F),
      paper: Color(0xFFEDE6D0),
      paperDeep: Color(0xFFD5C8A4),
      ink: Color(0xFF20242E),
      inkSoft: Color(0xFF6A7080),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      selected: Color(0xFF8FA8D0),
      cursor: Color(0xFFC0C6D4),
    ),
    PressThemeDef(
      id: 'coffee',
      name: 'Coffee Ring',
      deskDark: Color(0xFF3E2E1E),
      deskMid: Color(0xFF58402A),
      deskDeep: Color(0xFF241A0E),
      paper: Color(0xFFF3E8D2),
      paperDeep: Color(0xFFE0CCA2),
      ink: Color(0xFF33241A),
      inkSoft: Color(0xFF82684A),
      accent: Color(0xFF9A5A24),
      accentLight: Color(0xFFC98A4E),
      accentDark: Color(0xFF6E3E16),
      selected: Color(0xFFD99A4E),
      cursor: Color(0xFF9A5A24),
    ),
    PressThemeDef(
      id: 'library',
      name: 'Library Oak',
      deskDark: Color(0xFF2E2418),
      deskMid: Color(0xFF443722),
      deskDeep: Color(0xFF181208),
      paper: Color(0xFFF6EFDC),
      paperDeep: Color(0xFFE6D6B2),
      ink: Color(0xFF2A2114),
      inkSoft: Color(0xFF77644A),
      accent: Color(0xFF1B7A4D),
      accentLight: Color(0xFF4FA878),
      accentDark: Color(0xFF11522F),
      selected: Color(0xFF6FCF97),
      cursor: Color(0xFF1B7A4D),
    ),
    PressThemeDef(
      id: 'sepia',
      name: 'Sepia Study',
      deskDark: Color(0xFF38302A),
      deskMid: Color(0xFF4E443A),
      deskDeep: Color(0xFF201B16),
      paper: Color(0xFFEFE2C6),
      paperDeep: Color(0xFFDCC79E),
      ink: Color(0xFF33291E),
      inkSoft: Color(0xFF7C6B55),
      accent: Color(0xFF8C5A2B),
      accentLight: Color(0xFFBE8A52),
      accentDark: Color(0xFF5E3A1A),
      selected: Color(0xFFC99A5B),
      cursor: Color(0xFF8C5A2B),
    ),
    PressThemeDef(
      id: 'inkwell',
      name: 'Inkwell Black',
      deskDark: Color(0xFF1A1A1E),
      deskMid: Color(0xFF2A2A30),
      deskDeep: Color(0xFF0C0C0E),
      paper: Color(0xFF2E2E36),
      paperDeep: Color(0xFF1E1E24),
      ink: Color(0xFFF0EAD8),
      inkSoft: Color(0xFF9A94A0),
      accent: Color(0xFFD94A56),
      accentLight: Color(0xFFF08A94),
      accentDark: Color(0xFF96262F),
      selected: Color(0xFF5A5A6E),
      cursor: Color(0xFFD94A56),
    ),
    PressThemeDef(
      id: 'parchment',
      name: 'Parchment',
      deskDark: Color(0xFF4A3B28),
      deskMid: Color(0xFF62503A),
      deskDeep: Color(0xFF2A2114),
      paper: Color(0xFFFAF3E0),
      paperDeep: Color(0xFFEADFB8),
      ink: Color(0xFF3A2E1E),
      inkSoft: Color(0xFF8A7554),
      accent: Color(0xFF7A5A2E),
      accentLight: Color(0xFFB98A4A),
      accentDark: Color(0xFF54401E),
      selected: Color(0xFFD4A94E),
      cursor: Color(0xFF7A5A2E),
    ),
    PressThemeDef(
      id: 'copperplate',
      name: 'Copperplate',
      deskDark: Color(0xFF2A1F1A),
      deskMid: Color(0xFF3E2E26),
      deskDeep: Color(0xFF17100C),
      paper: Color(0xFFF2EAD6),
      paperDeep: Color(0xFFDECFAE),
      ink: Color(0xFF2E2420),
      inkSoft: Color(0xFF7A6C60),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      selected: Color(0xFFE09E5A),
      cursor: Color(0xFFB87333),
    ),
    PressThemeDef(
      id: 'editorial',
      name: 'Editorial Red',
      deskDark: Color(0xFF3A1420),
      deskMid: Color(0xFF52202E),
      deskDeep: Color(0xFF200A12),
      paper: Color(0xFFF7EFE0),
      paperDeep: Color(0xFFE5D4B8),
      ink: Color(0xFF2E1A20),
      inkSoft: Color(0xFF7C5E66),
      accent: Color(0xFFC0392B),
      accentLight: Color(0xFFE88A7E),
      accentDark: Color(0xFF8A2418),
      selected: Color(0xFFE8A33D),
      cursor: Color(0xFFC0392B),
    ),
    PressThemeDef(
      id: 'forest',
      name: 'Forest Desk',
      deskDark: Color(0xFF22301F),
      deskMid: Color(0xFF33452C),
      deskDeep: Color(0xFF121A0E),
      paper: Color(0xFFF1EAD6),
      paperDeep: Color(0xFFDACFAE),
      ink: Color(0xFF222E1C),
      inkSoft: Color(0xFF6A7458),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      selected: Color(0xFF9AB86A),
      cursor: Color(0xFFC9A227),
    ),
    PressThemeDef(
      id: 'navy',
      name: 'Navy Newsroom',
      deskDark: Color(0xFF16233F),
      deskMid: Color(0xFF24365C),
      deskDeep: Color(0xFF0C1526),
      paper: Color(0xFFF2EEE4),
      paperDeep: Color(0xFFDCD2B8),
      ink: Color(0xFF1A2440),
      inkSoft: Color(0xFF5E6A88),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      selected: Color(0xFF7FA8C9),
      cursor: Color(0xFFC0C6D4),
    ),
    PressThemeDef(
      id: 'burgundy',
      name: 'Burgundy Binding',
      deskDark: Color(0xFF3A1A2E),
      deskMid: Color(0xFF552842),
      deskDeep: Color(0xFF200E18),
      paper: Color(0xFFF5ECDC),
      paperDeep: Color(0xFFE2D0B2),
      ink: Color(0xFF2E1626),
      inkSoft: Color(0xFF7A5E6E),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      selected: Color(0xFFE0A83C),
      cursor: Color(0xFFD4AF37),
    ),
    PressThemeDef(
      id: 'sage',
      name: 'Sage Journal',
      deskDark: Color(0xFF2E3B2E),
      deskMid: Color(0xFF44523E),
      deskDeep: Color(0xFF161E14),
      paper: Color(0xFFF4EEDC),
      paperDeep: Color(0xFFE0D4B4),
      ink: Color(0xFF263026),
      inkSoft: Color(0xFF6E7A66),
      accent: Color(0xFF8A9A5B),
      accentLight: Color(0xFFB8C48E),
      accentDark: Color(0xFF5E6A3E),
      selected: Color(0xFFA3BE8C),
      cursor: Color(0xFF8A9A5B),
    ),
    PressThemeDef(
      id: 'charcoal',
      name: 'Charcoal Sketch',
      deskDark: Color(0xFF242424),
      deskMid: Color(0xFF383838),
      deskDeep: Color(0xFF121212),
      paper: Color(0xFFEDE8DA),
      paperDeep: Color(0xFFD2C8B2),
      ink: Color(0xFF262626),
      inkSoft: Color(0xFF6E6A60),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      selected: Color(0xFFC9A227),
      cursor: Color(0xFFB87333),
    ),
    PressThemeDef(
      id: 'linen',
      name: 'Cream Linen',
      deskDark: Color(0xFF4E4438),
      deskMid: Color(0xFF655949),
      deskDeep: Color(0xFF2C2620),
      paper: Color(0xFFFBF6E9),
      paperDeep: Color(0xFFEDE0C2),
      ink: Color(0xFF3A322A),
      inkSoft: Color(0xFF8A7E6E),
      accent: Color(0xFF2E5A88),
      accentLight: Color(0xFF5E8AC0),
      accentDark: Color(0xFF1E3A5C),
      selected: Color(0xFF8FB8DE),
      cursor: Color(0xFF2E5A88),
    ),
    PressThemeDef(
      id: 'walnut',
      name: 'Walnut Study',
      deskDark: Color(0xFF3B2416),
      deskMid: Color(0xFF5C3A21),
      deskDeep: Color(0xFF201309),
      paper: Color(0xFFF5EFE0),
      paperDeep: Color(0xFFE2D2AE),
      ink: Color(0xFF2E1F12),
      inkSoft: Color(0xFF7A6448),
      accent: Color(0xFF1D4E9E),
      accentLight: Color(0xFF5E8AC9),
      accentDark: Color(0xFF12305E),
      selected: Color(0xFF7FA8D9),
      cursor: Color(0xFF1D4E9E),
    ),
    PressThemeDef(
      id: 'olive',
      name: 'Olive Press',
      deskDark: Color(0xFF3F4226),
      deskMid: Color(0xFF5E6238),
      deskDeep: Color(0xFF22240F),
      paper: Color(0xFFF1EAD8),
      paperDeep: Color(0xFFDCCFA8),
      ink: Color(0xFF2E3018),
      inkSoft: Color(0xFF72744E),
      accent: Color(0xFF935116),
      accentLight: Color(0xFFC98848),
      accentDark: Color(0xFF63350E),
      selected: Color(0xFFD9A441),
      cursor: Color(0xFF935116),
    ),
    PressThemeDef(
      id: 'porcelain',
      name: 'Porcelain',
      deskDark: Color(0xFFE8E0D0),
      deskMid: Color(0xFFF2EAD8),
      deskDeep: Color(0xFFCFC2A8),
      paper: Color(0xFFFFFFFF),
      paperDeep: Color(0xFFF0EAD8),
      ink: Color(0xFF2A2118),
      inkSoft: Color(0xFF8A7E6A),
      accent: Color(0xFF2E5A88),
      accentLight: Color(0xFF5E8AC0),
      accentDark: Color(0xFF1E3A5C),
      selected: Color(0xFF9AC2E8),
      cursor: Color(0xFF2E5A88),
    ),
    PressThemeDef(
      id: 'tobacco',
      name: 'Tobacco Leaf',
      deskDark: Color(0xFF4A2E1A),
      deskMid: Color(0xFF64402A),
      deskDeep: Color(0xFF28170C),
      paper: Color(0xFFF0E4CC),
      paperDeep: Color(0xFFDCC89E),
      ink: Color(0xFF33200F),
      inkSoft: Color(0xFF7E6448),
      accent: Color(0xFFD4AC0D),
      accentLight: Color(0xFFF0D47E),
      accentDark: Color(0xFF96700A),
      selected: Color(0xFFE8B93C),
      cursor: Color(0xFFD4AC0D),
    ),
  ];

  static PressThemeDef byId(String id, {PressThemeDef? custom}) {
    if (id == 'custom') {
      return custom ?? all.first;
    }
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Cell rendering styles — how the paper squares look and feel.
/// 0-2 = FREE, 3+ = PRO.
class CellStyles {
  static const names = [
    'Letterpress',
    'Typewriter',
    'Newsprint',
    'Parchment',
    'Copperplate',
    'Ink Wash',
    'Manuscript',
    'Noir',
  ];
  static const descriptions = [
    'Classic debossed print squares',
    'Sharp mono office-type cells',
    'Raw column newsprint, thin rules',
    'Aged vellum with soft edges',
    'Engraved copperplate borders',
    'Brushed ink-wash texture cells',
    'Hand-ruled manuscript squares',
    'Black tiles, chalk-white ink',
  ];

  /// Styles free players may use.
  static const freeCount = 3;
  static bool isPro(int index) => index >= freeCount;
}

/// Resolves the effective cell look from [theme] + [styleIndex].
class CellLook {
  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color inkSoft;
  final Color block;
  final double radius;
  final double depth;
  final FontWeight weight;

  const CellLook({
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.inkSoft,
    required this.block,
    required this.radius,
    required this.depth,
    required this.weight,
  });

  static CellLook of(PressThemeDef t, int styleIndex) {
    final i = styleIndex.clamp(0, CellStyles.names.length - 1);
    switch (i) {
      case 0: // Letterpress
        return CellLook(
          paper: t.paper,
          paperDeep: t.paperDeep,
          ink: t.ink,
          inkSoft: t.inkSoft,
          block: t.deskDeep,
          radius: 6,
          depth: 3,
          weight: FontWeight.w800,
        );
      case 1: // Typewriter
        return CellLook(
          paper: t.paper,
          paperDeep: t.paperDeep,
          ink: t.ink,
          inkSoft: t.inkSoft,
          block: t.deskDeep,
          radius: 2,
          depth: 2,
          weight: FontWeight.w700,
        );
      case 2: // Newsprint
        return CellLook(
          paper: t.paper,
          paperDeep: t.paper,
          ink: t.ink,
          inkSoft: t.inkSoft,
          block: t.deskDeep,
          radius: 1,
          depth: 1,
          weight: FontWeight.w600,
        );
      case 3: // Parchment
        return CellLook(
          paper: t.paper,
          paperDeep: t.paperDeep,
          ink: t.ink,
          inkSoft: t.inkSoft,
          block: t.deskDeep,
          radius: 12,
          depth: 4,
          weight: FontWeight.w700,
        );
      case 4: // Copperplate
        return CellLook(
          paper: t.paper,
          paperDeep: t.paperDeep,
          ink: t.ink,
          inkSoft: t.accentDark,
          block: t.deskDeep,
          radius: 4,
          depth: 5,
          weight: FontWeight.w800,
        );
      case 5: // Ink Wash
        return CellLook(
          paper: t.paperDeep,
          paperDeep: t.paper,
          ink: t.ink,
          inkSoft: t.inkSoft,
          block: t.deskDeep,
          radius: 8,
          depth: 2,
          weight: FontWeight.w600,
        );
      case 6: // Manuscript
        return CellLook(
          paper: t.paper,
          paperDeep: t.paperDeep,
          ink: t.accentDark,
          inkSoft: t.inkSoft,
          block: t.deskDeep,
          radius: 3,
          depth: 3,
          weight: FontWeight.w700,
        );
      default: // Noir
        return const CellLook(
          paper: Color(0xFF23232B),
          paperDeep: Color(0xFF141419),
          ink: Color(0xFFF2EEE2),
          inkSoft: Color(0xFF9A94A8),
          block: Color(0xFF0B0B0E),
          radius: 6,
          depth: 4,
          weight: FontWeight.w800,
        );
    }
  }
}
