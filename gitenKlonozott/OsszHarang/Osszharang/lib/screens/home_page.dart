import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

// Saját fájlok importja

import '../beallitasok.dart';
import '../constants/strings.dart';
import '../constants/theme.dart';
import '../providers/home_provider.dart';
import 'ebreszto.dart';


class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // --- WEBOLDAL MEGNYITÁSA ---
  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://osszharang.com');
    if (!await launcher.launchUrl(url, mode: launcher.LaunchMode.externalApplication)) {
      debugPrint('Hiba a weboldal megnyitásakor');
    }
  }

  // --- INFORMÁCIÓS ABLAK ---
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.white24, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_edu, color: Colors.orangeAccent, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        "Miért szól a harang?",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(
                          AppStrings.trianonDescription,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                          "BEZÁRÁS",
                          style: TextStyle(color: Colors.cyanAccent.shade400, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI ÉPÍTÉS ---
  @override
  Widget build(BuildContext context) {
    // ITT CSATLAKOZUNK RÁ A PROVIDERRE (AZ "AGYRA"):
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/hatter.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 4),

                      if (provider.isRinging && provider.isPaused)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            "ELNÉMÍTVA",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 12),
                          ),
                        ),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: provider.isRinging ? 180 : 70,
                        child: provider.isRinging
                            ? Image.asset('assets/harangozas.gif', fit: BoxFit.contain)
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/harangborito.png', fit: BoxFit.contain),
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "ÖSSZHARANG",
                        style: TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 8.0, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "TRIANONI EMLÉKEZÉS • JÚNIUS 4.",
                        style: TextStyle(color: Colors.orange[300], fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "16:32 KözépEU idő",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),

                      const SizedBox(height: 25),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: provider.isRinging ? _buildRingingUI(provider) : _buildCountdownUI(provider),
                      ),

                      const SizedBox(height: 30),

                      if (!provider.isRinging)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildOutlinedButton(
                              icon: Icons.play_arrow_outlined,
                              label: "Teszt 10mp",
                              onTap: provider.startImmediateTest, // Provider hívása
                            ),
                            const SizedBox(width: 15),
                            _buildOutlinedButton(
                              icon: Icons.settings_outlined,
                              label: "Beállítások",
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BeallitasokPage())
                                ).then((_) => provider.loadSettings());
                              },
                            ),
                          ],
                        ),

                      const SizedBox(height: 30),

                      if (!provider.isRinging)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTextButton(
                                icon: Icons.alarm,
                                label: "Ébresztő",
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EbresztoPage()));
                                }
                            ),
                            const SizedBox(width: 8),
                            _buildTextButton(
                                icon: Icons.info_outline,
                                label: "Információ",
                                onTap: () => _showInfoDialog(context)
                            ),
                            const SizedBox(width: 8),
                            _buildTextButton(
                                icon: Icons.open_in_new,
                                label: "Weboldal",
                                onTap: _launchUrl
                            ),
                          ],
                        ),

                      const Spacer(flex: 2),

                      const Text(
                        "1920. JÚNIUS 4. — TRIANONI BÉKEDIKTÁTUM",
                        style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 10),
                      Image.asset('assets/trianon.gif', height: 110),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                if (provider.isNoonBellActive && !provider.isRinging)
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.wb_sunny_outlined, color: Colors.amberAccent, size: 14),
                          SizedBox(width: 5),
                          Text("Déli harang", style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI RÉSZEGYSÉGEK ---

  Widget _buildCountdownUI(HomeProvider provider) {
    int days = provider.timeUntilTrianon.inDays;
    int hours = provider.timeUntilTrianon.inHours.remainder(24);
    int minutes = provider.timeUntilTrianon.inMinutes.remainder(60);
    int seconds = provider.timeUntilTrianon.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeBox(days.toString(), "NAP"),
        _buildColon(),
        _buildTimeBox(hours.toString().padLeft(2, '0'), "ÓRA"),
        _buildColon(),
        _buildTimeBox(minutes.toString().padLeft(2, '0'), "PERC"),
        _buildColon(),
        _buildTimeBox(seconds.toString().padLeft(2, '0'), "MP"),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildColon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 15),
      child: Text(":", style: TextStyle(fontSize: 24, color: Colors.white54, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRingingUI(HomeProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  Widget _buildOutlinedButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54, width: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildTextButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}