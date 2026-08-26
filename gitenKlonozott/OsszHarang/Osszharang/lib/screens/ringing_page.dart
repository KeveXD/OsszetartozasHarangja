import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Saját fájlok
import '../constants/theme.dart';
import '../providers/home_provider.dart';

class RingingPage extends StatelessWidget {
  const RingingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    // --- DINAMIKUS SZÖVEGEK ÉS LÁTHATÓSÁG KISZÁMÍTÁSA ---
    String mainTitle = "ÖSSZHARANG";
    String subTitle = "TRIANONI EMLÉKEZÉS • JÚNIUS 4.";
    String timeInfo = "16:32 KözépEU idő";
    bool showMiddleBellImage = false;

    if (provider.currentAlarmId == 804) {
      // DÉLI HARANGSZÓ
      mainTitle = "DÉLI HARANGSZÓ";
      subTitle = "MINDEN NAP PONTBAN DÉLBEN";
      timeInfo = "A nándorfehérvári diadal emléke";
      showMiddleBellImage = true;
    } else if (provider.currentAlarmId == 888) {
      // ÉBRESZTŐ
      mainTitle = "ÉBRESZTŐ";
      subTitle = "SAJÁT HARANGOZÁS";
      timeInfo = "Itt az idő!";
      showMiddleBellImage = false;
    } else if (provider.currentAlarmId == 999) {
      // TESZT
      mainTitle = "TESZT";
      subTitle = "PRÓBA HARANGOZÁS";
      timeInfo = "A hangrendszer ellenőrzése";
      showMiddleBellImage = true;
    } else if (provider.currentAlarmId == 604) {
      // TRIANON
      showMiddleBellImage = false;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBase,
      body: Stack(
        children: [
          // Háttérkép
          Positioned.fill(
            child: Image.asset(
              'assets/hatter.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  if (provider.isPaused)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        "ELNÉMÍTVA",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 12),
                      ),
                    ),

                  // Fő animáció (Nagy harang)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 180,
                    child: Image.asset('assets/harangozas.gif', fit: BoxFit.contain),
                  ),

                  const SizedBox(height: 15),

                  // Feliratok
                  Text(
                    mainTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 8.0, fontWeight: FontWeight.w300, ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subTitle,
                    style: TextStyle(color: Colors.orange[300], fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold, ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    timeInfo,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, ),
                  ),

                  const SizedBox(height: 40),

                  // KÖZÉPSŐ KIS HARANG (Teszt és Déli harang esetén)
                  if (showMiddleBellImage)
                    GestureDetector(
                      onTap: provider.togglePause,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ClipRRect(
                          key: ValueKey<bool>(provider.isPaused),
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            provider.isPaused ? 'assets/deliharangfolytatas.png' : 'assets/deliharang.gif',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                  if (showMiddleBellImage) const SizedBox(height: 30),

                  // VEZÉRLŐ GOMBOK
                  _buildRingingUI(provider),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingingUI(HomeProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ELNÉMÍTÁS / FOLYTATÁS GOMB
        SizedBox(
          width: 260,
          child: ElevatedButton.icon(
            onPressed: provider.togglePause,
            icon: Icon(provider.isPaused ? Icons.play_arrow : Icons.volume_off, color: Colors.white),
            label: Text(
                provider.isPaused ? "FOLYTATÁS (${provider.ringingSecondsRemaining} mp)" : "Elnémítás",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.isPaused ? const Color(0xFF1DB954) : const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
          ),
        ),

        // LEÁLLÍTÁS GOMB - CSAK ÉBRESZTŐNÉL (888)
        if (provider.currentAlarmId == 888) ...[
          const SizedBox(height: 15),
          SizedBox(
            width: 260,
            child: ElevatedButton.icon(
              onPressed: provider.stopRinging,
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              label: const Text(
                  "ÉBRESZTŐ LEÁLLÍTÁSA",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
            ),
          ),
        ],

        const SizedBox(height: 15),

        Text(
          "${provider.ringingSecondsRemaining} / ${provider.totalRingingSeconds} mp",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white, letterSpacing: 1.5),
        ),
      ],
    );
  }
}