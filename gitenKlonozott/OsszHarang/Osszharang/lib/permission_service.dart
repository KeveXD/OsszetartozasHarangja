import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  // Ez itt a "mappánk" neve az iratszekrényben. Ezt használjuk azonosítóként.
  // Private változó (aláhúzással kezdődik), hogy más fájlokból ne lehessen elrontani.
  static const String _key = 'permission_dialog_shown';

  // Ellenőrzi, hogy mutattuk-e már a popupot a felhasználónak.
  static Future<bool> shouldShowDialog() async {
    // 1. LÉPÉS: Kinyitjuk az iratszekrényt.
    // Az 'await' azért kell, mert beletelhet egy-két tizedmásodpercbe,
    // amíg a telefon a memóriából előkeresi az appunk fájlját.
    // A 'prefs' változó maga az iratszekrény lesz.
    final prefs = await SharedPreferences.getInstance();

    // 2. LÉPÉS: Megmondjuk, mit keresünk!
    // Itt mondjuk meg a prefs-nek: "Keresd meg a '_key' (azaz 'permission_dialog_shown') nevű mappát, és vedd ki belőle a True/False cetlit!"
    // A '??' (null-aware) operátor egy zseniális dolog a Dartban. Azt jelenti:
    // "Ha a getBool(_key) eredménye NULL (vagyis még üres a mappa, mert most indult először az app),
    // akkor adj vissza TRUE-t alapértelmezettként."
    return prefs.getBool(_key) ?? true;
  }

  // Elmenti, hogy a popup már megjelent, többet ne zaklassuk a usert.
  static Future<void> setDialogShown() async {
    // 1. LÉPÉS: Ismét kinyitjuk az iratszekrényt.
    final prefs = await SharedPreferences.getInstance();

    // 2. LÉPÉS: Mentünk.
    // Itt mondjuk meg: "Fogj egy cetlit, írd rá, hogy FALSE, és tedd be a '_key' nevű mappába."
    // (Azért mentünk FALSE-t, mert a fenti függvény azt kérdezi: "Mutassuk-e a dialógust?" - Ha már látta, akkor FALSE, azaz ne mutassuk.)
    await prefs.setBool(_key, false);
  }
}