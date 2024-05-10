import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cod_soft_alarm/Edit_page.dart';
import 'package:cod_soft_alarm/ring.dart';
import 'package:cod_soft_alarm/tobbi/ido.dart';
import 'package:cod_soft_alarm/tobbi/logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';



class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late List<AlarmSettings> harangok;

  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }
    harangokBetoltese();
    subscription ??= Alarm.ringStream.stream.listen(
          (alarmSettings) => navigateToRingScreen(alarmSettings),
    );
  }

  void harangokBetoltese() {
    setState(() {
      harangok = Alarm.getAlarms();
      harangok.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExampleAlarmRingScreen(alarmSettings: alarmSettings),
        ));
    harangokBetoltese();
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditPage(
              alarmSettings: settings,
            )));

    if (res != null && res == true) harangokBetoltese();
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  Future<void> checkAndroidExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      alarmPrint('Requesting external storage permission...');
      final res = await Permission.storage.request();
      alarmPrint(
        'External storage permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(34, 66, 82, 1.0), // Sötétkék (RGB: 0, 0, 139)
                Color.fromRGBO(124, 163, 178, 1.0), // Világoskék (RGB: 173, 216, 230)

              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Center(child: Realtime()),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => navigateToAlarmScreen(null),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              harangok.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: harangok.length,
                  itemBuilder: (context, index) {
                    return _buildHarangKartya(harangok[index], index);
                  },
                ),
              )
                  : Expanded(
                child: Column(
                  children: [
                    Text(
                      "",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool success = await Logic.createAndSaveAlarm();
                        if (success) harangokBetoltese();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(141, 77, 72, 1.0), // Háttérszín beállítása
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Margó beállítása
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Gomb alakjának beállítása
                        ),
                      ),
                      label: Text(
                        "Összharang",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      icon: Icon(Icons.notifications, size: 30, color: Color.fromRGBO(34, 66, 82, 1.0)
                          ,), // Harang ikon hozzáadása

                    ),

                    SizedBox(height: 20),
                    const Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Vegyük kezünkbe a trianoni emlékharangozást!",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "1920. június 4-én, 16:32 perckor aláírták a trianoni békediktátumot a versailles-i Nagy-Trianon kastély 52 méter hosszú és 7 méter széles folyosóján, a La galérie des Cotelle-ben.",
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Ezen a napon Magyarország elveszítette területének kétharmadát, a magyar népesség egyharmada pedig a határokon kívülre került. Ennek emlékére évekig országszerte megszólaltak a templomharangok ebben az időben. Ez a hagyomány azonban 1945 után teljesen megszűnt. 2012-ben a három, nagy keresztény egyház visszautasította azt a kormányzati kérést, hogy június 4-én, a Nemzeti Összetartozás Napján délután, a trianoni szerződés aláírásának időpontjában konduljanak meg a templomok harangjai, s szóljanak egy percig a megemlékezés részeként.",
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Ezért gondoltuk úgy, hogy saját kezünkbe kell venni ennek a harangozásnak \"feladatát.",
                              style: TextStyle(fontSize: 16),
                            ),
                            // A további szövegeket itt folytathatod...
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHarangKartya(AlarmSettings alarm, int index) {
    TimeOfDay time = TimeOfDay.fromDateTime(alarm.dateTime);
    String formattedDate = DateFormat('EEEE, dd MMM', 'hu_HU').format(alarm.dateTime);

    DateTime now = DateTime.now();
    DateTime alarmDate = alarm.dateTime;
    Duration difference = alarmDate.difference(now);
    int daysUntilAlarm = difference.inDays;

    String countdownText;
    if (daysUntilAlarm == 0) {
      countdownText = "Ma";
    } else {
      countdownText = "$daysUntilAlarm nap";
    }

    return GestureDetector(
      //onTap: () => navigateToAlarmScreen(harangok[index]),
      child: Slidable(
        closeOnScroll: true,
        endActionPane: ActionPane(extentRatio: 0.4, motion: const ScrollMotion(), children: [
          SlidableAction(
            borderRadius: BorderRadius.circular(12),
            onPressed: (context) {
              Alarm.stop(alarm.id);
              harangokBetoltese();
            },
            icon: Icons.delete_forever,
            backgroundColor: Colors.red.shade700,
          )
        ]),
        child: Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Harangozás",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        countdownText,
                        style: TextStyle(
                          fontSize: 24,
                          color: daysUntilAlarm == 0 ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.doorbell_rounded,
                    size: 120,
                    color: Colors.grey.shade600, // Halványabb szín
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }





}
