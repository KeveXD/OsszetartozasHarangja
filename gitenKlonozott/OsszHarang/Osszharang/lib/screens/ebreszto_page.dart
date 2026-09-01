import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Saját fájlok importja
import '../constants/theme.dart'; // Ellenőrizd az útvonalat!
import '../providers/ebreszto_provider.dart'; // FONTOS IMPORT!

class EbresztoPage extends StatelessWidget {
  const EbresztoPage({Key? key}) : super(key: key);

  // --- KOMPLEX IDŐPONT ÉS DÁTUM VÁLASZTÓ ---
  // Mivel a dialógusokhoz "context" kell, ezt a funkciót a UI fájlban tartjuk
  Future<void> _pickDateTime(BuildContext context, EbresztoProvider provider) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: provider.selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.cyanAccent.shade400,
              onPrimary: Colors.black,
              surface: const Color(0xFF1E2328),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: provider.selectedDateTime.hour, minute: provider.selectedDateTime.minute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.cyanAccent.shade400,
              onPrimary: Colors.black,
              surface: const Color(0xFF1E2328),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    DateTime newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (newDateTime.isBefore(DateTime.now())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A múltba nem állíthatsz be ébresztőt!'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // Szólunk a providernek, hogy mentse el az új időpontot
    provider.updateDateTime(newDateTime);
  }

  @override
  Widget build(BuildContext context) {
    // ITT KÉRJÜK LE AZ ADATOKAT A PROVIDERBŐL:
    final provider = context.watch<EbresztoProvider>();

    final String formattedDate = DateFormat('yyyy. MM. dd.').format(provider.selectedDateTime);
    final String formattedTime = DateFormat('HH:mm').format(provider.selectedDateTime);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, left: 15.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text("Vissza", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                  child: Text("Ébresztő", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildCard(
                        icon: Icons.alarm,
                        iconColor: Colors.orangeAccent,
                        title: "Saját harangozás",
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Dátum és Időpont", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                    const SizedBox(height: 5),
                                    InkWell(
                                      onTap: () => _pickDateTime(context, provider),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                  color: provider.isAlarmOn ? Colors.cyanAccent.shade400 : Colors.white,
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2.0
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                  color: provider.isAlarmOn ? Colors.cyanAccent.withOpacity(0.7) : Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: provider.isAlarmOn,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: provider.toggleAlarm,
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15.0),
                              child: Divider(color: Colors.white10, thickness: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Harangozás hossza", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                Text("${provider.durationSeconds} mp", style: TextStyle(color: Colors.cyanAccent.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Slider(
                              value: provider.durationSeconds.toDouble(),
                              min: 10,
                              max: 300,
                              divisions: 29,
                              activeColor: Colors.cyanAccent.shade400,
                              inactiveColor: Colors.white10,
                              onChanged: (val) => provider.saveDuration(val.toInt()),
                            ),
                          ],
                        ),
                      ),
                      _buildCard(
                        icon: Icons.volume_up,
                        iconColor: Colors.greenAccent,
                        title: "Hangbeállítások",
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Rezgés harangozáskor", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                CupertinoSwitch(
                                  value: provider.vibration,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: provider.saveVibration,
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                const Icon(Icons.volume_down, color: Colors.white54, size: 20),
                                Expanded(
                                  child: Slider(
                                    value: provider.volume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Colors.cyanAccent.shade400,
                                    inactiveColor: Colors.white10,
                                    onChanged: provider.saveVolume,
                                  ),
                                ),
                                Icon(Icons.volume_up, color: Colors.cyanAccent.shade400, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildCard({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}