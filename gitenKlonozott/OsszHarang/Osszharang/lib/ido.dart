import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Saját téma importálása
import 'theme.dart';

class Realtime extends StatefulWidget {
  const Realtime({Key? key});

  @override
  _RealtimeState createState() => _RealtimeState();
}

class _RealtimeState extends State<Realtime> {
  late StreamController<DateTime> _clockStreamController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('hu', null);

    _clockStreamController = StreamController<DateTime>.broadcast();
    _clockStreamController.add(DateTime.now());

    _startClock();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _clockStreamController.add(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _clockStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _clockStreamController.stream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();

        String datePart = DateFormat('yyyy. MMM d. EEEE', 'hu').format(now).toUpperCase();
        String timeMain = DateFormat('HH:mm', 'hu').format(now);
        String timeSecond = DateFormat('ss', 'hu').format(now);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dátum (Fehér)
            Text(
              datePart,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary, // FEHÉR
                letterSpacing: 1.5,
                shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Óra : Perc (FEHÉR)
                Text(
                  timeMain,
                  style: const TextStyle(
                    fontSize: 55,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary, // EZ A LÉNYEG: FEHÉR
                    height: 1.0,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                ),

                // Kettőspont (Piros)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    ":",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentRed,
                      height: 1.0,
                    ),
                  ),
                ),

                // Másodperc (Piros)
                Text(
                  timeSecond,
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentRed, // Ez maradhat piros az effekt miatt
                    height: 1.0,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: AppTheme.accentRed.withOpacity(0.5),
                        offset: const Offset(0, 0),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}