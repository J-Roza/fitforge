/// Tokens de mise en page. À utiliser à la place des valeurs « au jugé »
/// pour que tous les écrans partagent les mêmes espacements et rayons.
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  /// Marge latérale des écrans.
  static const double screen = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();
  /// Chips, badges, puces.
  static const double sm = 8;
  /// Champs, boutons, tuiles internes.
  static const double md = 12;
  /// Toutes les cartes.
  static const double lg = 16;
  /// Bottom sheets, grandes images.
  static const double xl = 24;
}
