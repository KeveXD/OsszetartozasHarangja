  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:alarm/alarm.dart';
  import 'package:flutter/services.dart';
  import 'package:permission_handler/permission_handler.dart';

  // Saját fájlok importálása
  import 'permission_service.dart';
  import 'home_page.dart';
  import 'theme.dart';

  Future<void> main() async {
    // KRITIKUS: Ezt kötelező meghívni, mielőtt bármilyen aszinkron (await)
    // műveletet végeznénk a runApp() előtt. Ez köti össze a Flutter keretrendszert
    // az operációs rendszer natív részeivel.
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Inicializáljuk a harangozásért/ébresztésért felelős csomagot.
    await Alarm.init(showDebugLogs: true);

    runApp(
      MaterialApp(
        // Eltünteti a "DEBUG" szalagot a jobb felső sarokból.
        debugShowCheckedModeBanner: false,

        // GLOBÁLIS TÉMA BEÁLLÍTÁSA: Itt határozzuk meg az app alapvető kinézetét,
        // így betöltéskor és a rendszerablakoknál sem ugrik fel oda nem illő szín.
        theme: ThemeData(
          scaffoldBackgroundColor: AppTheme.backgroundBase, // A mi sötétzöldünk
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.backgroundBase,
            brightness: Brightness.dark, // Megmondjuk a Flutternek, hogy ez egy sötét app
          ),
          // A felugró (Dialog) ablakok kinézetét is hozzáigazítjuk a zöld-piros témánkhoz
          dialogTheme: DialogTheme(
            backgroundColor: AppTheme.backgroundBase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.borderDarkGreen, width: 1.5),
            ),
            titleTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ),
        // Az app belépési pontja ez az "őrszem" osztály lesz.
        home: const PermissionCheckWrapper(),
      ),
    );
  }

  // Ez az osztály felel azért, hogy az érdemi használat (HomePage) előtt
  // ellenőrizze és kikényszerítse a kritikus engedélyeket.
  class PermissionCheckWrapper extends StatefulWidget {
    const PermissionCheckWrapper({super.key});

    @override
    State<PermissionCheckWrapper> createState() => _PermissionCheckWrapperState();
  }

  // A 'with WidgetsBindingObserver' egy nagyon fontos trükk!
  // Ezzel feliratkozunk a rendszer eseményeire, így az app "látni" fogja,
  // mikor kerül a háttérbe, és mikor nyitják meg újra.
  class _PermissionCheckWrapperState extends State<PermissionCheckWrapper> with WidgetsBindingObserver {

    // ÁLLAPOTJELZŐ (FLAG): Ezzel akadályozzuk meg, hogy az app minden egyes megnyitáskor
    // bedobja a "Sikeres beállítás" ablakot. Csak akkor lesz igaz, ha a felhasználót
    // mi magunk küldtük el a telefon beállításaihoz.
    bool _wentToSettings = false;

    @override
    void initState() {
      super.initState();
      // Bejegyezzük ezt az osztályt megfigyelőként (observer),
      // hogy megkapjuk az életciklus eseményeket.
      WidgetsBinding.instance.addObserver(this);

      // Azonnal elindítjuk az engedélyek ellenőrzését a háttérben.
      _initLogic();
    }

    @override
    void dispose() {
      // Kötelező takarítás: ha az osztály megszűnik, leiratkozunk a megfigyelésről.
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }

    // ÉLETCYKLUS FIGYELŐ: Ez a függvény automatikusan meghívódik, amikor
    // az alkalmazás állapota megváltozik (pl. tálcára kerül, vagy visszatér).
    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      // AppLifecycleState.resumed = Az app újra előtérbe került, látható és használható.
      if (state == AppLifecycleState.resumed) {
        _checkAfterReturning(); // Ellenőrizzük, kapott-e engedélyt, amíg távol volt!
      }
    }

    // Fő logika, ami az app elindulásakor lefut.
    Future<void> _initLogic() async {
      // 1. Bekérjük az "egyszerűbb" engedélyeket (értesítés, pontos időzítés).
      // Ezek alapértelmezett rendszerablakok, nem akasztják meg a folyamatot.
      await [
        Permission.notification,
        Permission.scheduleExactAlarm,
      ].request();

      // 2. Megnézzük a SharedPreferences-ben, hogy mutattuk-e már valaha ezt a figyelmeztetést.
      bool firstTime = await PermissionService.shouldShowDialog();
      // 3. Lekérdezzük a kritikus (Overlay / Megjelenítés mások felett) engedély állapotát.
      bool isGranted = await Permission.systemAlertWindow.isGranted;

      // Ha még nem látta az ablakot ÉS nincs meg az engedély, akkor mutatjuk a felugrót.
      if (firstTime && !isGranted) {
        _showRequestDialog();
      }
    }

    // Ez a metódus fut le akkor, amikor az appot újra megnyitják (visszatér az előtérbe).
    Future<void> _checkAfterReturning() async {
      // Csak és kizárólag akkor foglalkozunk vele, ha az átirányítást MI indítottuk el
      // az engedélykérő ablak "BEÁLLÍTÁS" gombjával.
      if (_wentToSettings) {
        // Újra lekérdezzük, megadta-e végül az engedélyt a rendszerbeállításokban.
        bool isGranted = await Permission.systemAlertWindow.isGranted;

        if (isGranted) {
          _showSuccessDialog(); // Megdicsérjük!
        }

        // Fontos: Visszaállítjuk hamisra, hogy legközelebb, ha csak simán
        // megnyitja az appot, ne zaklassuk ezzel.
        _wentToSettings = false;
      }
    }

    // Az ablak, ami elmagyarázza, miért kell a "Megjelenítés más alkalmazások felett" engedély.
    void _showRequestDialog() {
      // Feljegyezzük, hogy ezt az ablakot most látta, így magától többet nem fog felugrani
      // (a felhasználónak a Beállítások oldalon a manuális gombbal kell majd próbálkoznia, ha elutasítja).
      PermissionService.setDialogShown();

      showDialog(
        context: context,
        barrierDismissible: false, // Nem lehet bezárni a hátteren való kattintással.
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: AppTheme.accentRed),
              const SizedBox(width: 10),
              const Text("Fontos Engedély"),
            ],
          ),
          // Mivel hosszú a szöveg, betesszük egy görgethető (scrollable) nézetbe
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Üdvözöl az ÖsszHarang!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  "Ahhoz, hogy az alkalmazás igazi ébresztőóraként (vekkerként, riasztóként) tudjon működni, és a harangozás idején lezárt képernyőnél is teljes méretben megjelenjen, engedélyezned kell a 'Megjelenítés más alkalmazások felett' opciót.",
                ),
                SizedBox(height: 15),
                Text(
                  "Hol találod meg, ha a gomb nem visz oda automatikusan?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "• Samsung: Beállítások ➡️ Alkalmazások ➡️ Különleges alkalmazáshozzáférés (jobb felső sarokban) ➡️ Megjelenés legfelül ➡️ Keresd meg az ÖsszHarangot és kapcsold be!\n\n"
                      "• Xiaomi / Poco: Beállítások ➡️ Alkalmazások ➡️ Engedélykezelés ➡️ Egyéb engedélyek ➡️ ÖsszHarang ➡️ 'Megjelenítés felugró ablakként' bekapcsolása.\n\n"
                      "• Egyéb Android: Beállítások ➡️ Alkalmazások ➡️ ÖsszHarang ➡️ Speciális ➡️ Megjelenítés más alkalmazások felett.",
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("KÉSŐBB", style: TextStyle(color: AppTheme.textTertiary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // KRITIKUS PONT: Itt állítjuk be a "zászlót", mielőtt elküldjük a beállításokba
                _wentToSettings = true;

                // JAVÍTVA: Ez adja a legnagyobb esélyt, hogy EGYENESEN a jó aloldalra vigye!
                await Permission.systemAlertWindow.request();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
              child: const Text("BEÁLLÍTÁS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    // Pozitív visszajelzés, ha megkapta a kritikus engedélyt.
    void _showSuccessDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 50),
          content: const Text("Sikeres beállítás! Az alkalmazás most már hibátlanul fog működni.", textAlign: TextAlign.center),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.borderDarkGreen),
                child: const Text("RENDBEN", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      // Vizuálisan a felhasználó egyből a HomePage-et (főoldalt) látja.
      // Ez az "őrszem" widget nem rajzol semmit a képernyőre, csak csendben megnyitja
      // a főoldalt, és a háttérből figyeli/kezeli a felugró ablakokat.
      return const HomePage();
    }
  }