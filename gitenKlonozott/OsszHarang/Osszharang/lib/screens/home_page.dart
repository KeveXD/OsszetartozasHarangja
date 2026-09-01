import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:osszharang_app/screens/ringing_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../beallitasok.dart';
import '../constants/strings.dart';
import '../constants/theme.dart';
import '../ebreszto.dart';
import '../providers/home_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://osszharang.com');
    if (!await launcher.launchUrl(url, mode: launcher.LaunchMode.externalApplication)) {
      debugPrint('Hiba a weboldal megnyitásakor');
    }
  }

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
                      const Text("Miért szól a harang?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("BEZÁRÁS", style: TextStyle(color: Colors.cyanAccent.shade400, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    // Képernyőméretek lekérése
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    if (provider.isRinging) {
      return const RingingPage();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/hatter.png', fit: BoxFit.cover),
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

                      // Statikus borítókép arányosan
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: screenHeight * 0.08, // Képernyőmagasság 8%-a
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/harangborito.png', fit: BoxFit.contain),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Címek relatív betűmérettel
                      Text(
                          "ÖSSZHARANG",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.08, // Képernyőszélesség 8%-a
                              letterSpacing: 8.0,
                              fontWeight: FontWeight.w300
                          )
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                          "TRIANONI EMLÉKEZÉS • JÚNIUS 4.",
                          style: TextStyle(
                              color: Colors.orange[300],
                              fontSize: screenWidth * 0.03,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                          "16:32 KözépEU idő",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.04
                          )
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Visszaszámláló
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: _buildCountdownUI(provider, screenWidth, screenHeight),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Felső gombok
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOutlinedButton(
                            icon: Icons.play_arrow_outlined,
                            label: "Teszt 10mp",
                            onTap: provider.startImmediateTest,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildOutlinedButton(
                            icon: Icons.settings_outlined,
                            label: "Beállítások",
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const BeallitasokPage())).then((_) => provider.loadSettings());
                            },
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Déli harang kapcsoló
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BeallitasokPage())).then((_) => provider.loadSettings());
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: ClipRRect(
                            key: ValueKey<bool>(provider.isNoonBellActive),
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              provider.isNoonBellActive ? 'assets/deliharangbekapcsolva.png' : 'assets/deliharangkikapcsolva.png',
                              height: screenHeight * 0.065, // Képernyőmagasság 6.5%-a
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.003),

                      // Alsó gombok
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTextButton(
                            icon: Icons.alarm,
                            label: "Ébresztő",
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const EbresztoPage()));
                            },
                            screenWidth: screenWidth,
                          ),
                          //SizedBox(width: screenWidth * 0.003),
                          _buildTextButton(
                            icon: Icons.info_outline,
                            label: "Információ",
                            onTap: () => _showInfoDialog(context),
                            screenWidth: screenWidth,
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          _buildTextButton(
                            icon: Icons.open_in_new,
                            label: "Weboldal",
                            onTap: _launchUrl,
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),

                      const Spacer(flex: 1),

                      Text(
                          "1920. JÚNIUS 4. — TRIANONI BÉKEDIKTÁTUM",
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: screenWidth * 0.025,
                              letterSpacing: 1.0
                          )
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Image.asset(
                          'assets/trianon.gif',
                          height: screenHeight * 0.12 // Képernyőmagasság 12%-a
                      ),

                      SizedBox(height: screenHeight * 0.03),
                    ],
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
  Widget _buildCountdownUI(HomeProvider provider, double screenWidth, double screenHeight) {
    int days = provider.timeUntilTrianon.inDays;
    int hours = provider.timeUntilTrianon.inHours.remainder(24);
    int minutes = provider.timeUntilTrianon.inMinutes.remainder(60);
    int seconds = provider.timeUntilTrianon.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeBox(days.toString(), "NAP", screenWidth, screenHeight),
        _buildColon(screenWidth, screenHeight),
        _buildTimeBox(hours.toString().padLeft(2, '0'), "ÓRA", screenWidth, screenHeight),
        _buildColon(screenWidth, screenHeight),
        _buildTimeBox(minutes.toString().padLeft(2, '0'), "PERC", screenWidth, screenHeight),
        _buildColon(screenWidth, screenHeight),
        _buildTimeBox(seconds.toString().padLeft(2, '0'), "MP", screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label, double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth * 0.16, // A képernyőszélesség 16%-a
      height: screenHeight * 0.09, // A képernyőmagasság 9%-a
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              value,
              style: TextStyle(
                  fontSize: screenWidth * 0.075, // Relatív betűméret a számoknak
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              )
          ),
          Text(
              label,
              style: TextStyle(
                  fontSize: screenWidth * 0.025, // Relatív betűméret a címkéknek
                  color: Colors.white70,
                  letterSpacing: 1.0
              )
          ),
        ],
      ),
    );
  }

  Widget _buildColon(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01, vertical: screenHeight * 0.015),
      child: Text(
          ":",
          style: TextStyle(
              fontSize: screenWidth * 0.05,
              color: Colors.white54,
              fontWeight: FontWeight.bold
          )
      ),
    );
  }

  Widget _buildOutlinedButton({required IconData icon, required String label, required VoidCallback onTap, required double screenWidth}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70, size: screenWidth * 0.045),
      label: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: screenWidth * 0.035)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54, width: 1.0),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.025),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildTextButton({required IconData icon, required String label, required VoidCallback onTap, required double screenWidth}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.015),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: screenWidth * 0.04),
            SizedBox(width: screenWidth * 0.01),
            Text(label, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.03)),
          ],
        ),
      ),
    );
  }
}