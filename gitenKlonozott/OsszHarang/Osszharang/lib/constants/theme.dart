import 'package:flutter/material.dart';

class AppTheme {
  // --- SZÍNEK (Sötét, letisztult / Dark & Elegant Edition) ---

  // 1. Háttér Alap (Mély, sötét tónus, nagyon finom szürkéskék/fekete beütéssel)
  static const Color backgroundBase = Color(0xFF0A0E11);

  // 2. Fólia (Fekete 60%-os átlátszósággal, ahogy a főoldalon is van)
  static const Color backgroundOverlay = Color(0x99000000);

  // 3. Kiemelő Szín (Narancsos-piros, ahogy a főoldali némítás gombnál)
  static const Color accentRed = Color(0xFFFF5722);

  // 4. Segédszín (Törtfehér / Világosszürke)
  static const Color textCream = Color(0xFFF2F5F4);

  // 5. Keret Szín (A név maradt, de a szín most már egy elegáns, áttetsző fehér a zöld helyett)
  static const Color borderDarkGreen = Colors.white24;

  // --- ÜVEG ALAPOK ---

  // Tiszta fekete alap, amit csak az átlátszóság (opacity) tesz üvegessé
  static const Color glassBackground = Colors.black;

  // Szöveg színek (A főoldallal szinkronban)
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white54;

  // --- STÍLUSOK (DEKORÁCIÓK) ---

  // Általános üveg doboz (Ezt használjuk most a főoldali számlálóknál is)
  static BoxDecoration glassDecoration({
    Color borderColor = Colors.white24, // Finom áttetsző fehér keret
    double opacity = 0.3, // 30%-os fekete áttetszőség
    double borderWidth = 1.0, // Vékonyabb, modernebb keret (5.0 helyett)
  }) {
    return BoxDecoration(
      color: glassBackground.withOpacity(opacity),
      borderRadius: BorderRadius.circular(15), // Finomabb lekerekítés (25 helyett 15)
      border: Border.all(
          color: borderColor,
          width: borderWidth
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Korábbi Zöld Keretes Üveg Doboz (A név maradt, a stílus új lett, hogy ne legyen hiba más oldalakon)
  static BoxDecoration greenGlassDecoration({
    double opacity = 0.4,
  }) {
    return BoxDecoration(
      color: glassBackground.withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      // Használjuk a frissített (most már áttetsző fehér) keretszínt
      border: Border.all(color: borderDarkGreen, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Az "Extrás" Óra stílusa (Ha esetleg a szerkesztő / Edit oldalon még felbukkan)
  static BoxDecoration glowingRedDecoration() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.6),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    );
  }
}