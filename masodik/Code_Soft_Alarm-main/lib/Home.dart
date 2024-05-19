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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/logo2.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3), // Áttetsző fekete szín használata
                BlendMode.dstATop, // Alapértelmezett keverési mód
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 0),
              const Center(child: Realtime()),
              const SizedBox(height: 0),
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
                        backgroundColor: const Color.fromRGBO(141, 77, 72, 1.0), // Háttérszín beállítása
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Margó beállítása
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Gomb alakjának beállítása
                        ),
                      ),
                      label: const Text(
                        "Összharang",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      icon: const Icon(
                        Icons.notifications,
                        size: 30,
                        color: Color.fromRGBO(34, 66, 82, 1.0),
                      ), // Harang ikon hozzáadása
                    ),
                    SizedBox(height: 20),
                    const Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "App. leírás:",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "http://osszharang.com",
                              style: TextStyle(fontSize: 16, color: Colors.white, decoration: TextDecoration.underline),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Vegyük kezünkbe a trianoni emlékharangozást!\n"
                                  "1920. június 4-én 16:32 perckor aláírták a trianoni békediktátumot a versailles-i Nagy-Trianon kastély 52 méter hosszú és 7 méter széles folyosóján, a La galérie des Cotelle-ben.\n"
                                  "Ezen a napon Magyarország elveszítette területének kétharmadát, a magyar népesség egyharmada pedig a határokon kívülre került. Ennek emlékére évekig országszerte megszólaltak a templomharangok ebben az időben. Ez a hagyomány azonban 1945 után teljesen megszűnt. 2012-ben a három, nagy keresztény egyház visszautasította azt a kormányzati kérést, hogy június 4-én, a Nemzeti Összetartozás Napján délután, a trianoni szerződés aláírásának időpontjában konduljanak meg a templomok harangjai, s szóljanak egy percig a megemlékezés részeként.\n"
                                  "Ezért gondoltuk úgy, hogy saját kezünkbe kell venni ennek a harangozásnak a feladatát.",
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Ez az applikáció nem tesz mást, mint minden évben figyelmezteti\n"
                                  "használóját az emlékezés szükségességére azzal, hogy június 4-én, 16:32-kor automatikusan megszólaltatja ezt az emlékharangot annyi másodpercre, amennyi az adott trianoni évforduló. Szintén megszólítja tulajdonosát, figyelmeztetve az esemény fontosságára.\n"
                                  "Miután a trianoni emléknapját és a Nemzeti Összetartozás Napját együtt kell reprezentálnia, ezért ez az applikáció az ÖSSZHARANG nevet kapta. Egyszerre szól az emlékezés és a jövőbe vetett hitünk, összetartozásunk hangján. Bárhol is érjen ezen harangozás pillanata, állj meg egy percre és tartsd magasba a telefonod. Lesznek, akik majd megkérdezik, mire vélhetik ezt a jelenetet. Akkor lehet-kell elmondani, hogy 1920-ban, ebben a pillanatban veszített el Magyarország területének háromnegyedét. Kifejthetjük a szükséges részletességig nemzeti tragédiánk hátterét.\n"
                                  "Ugyanakkor a harang azokért is szól, akik kint rekedtek a magyar határokon túl és idegen hatalmak, országok polgáraiként élik azóta is életüket. Nem felejtjük el, hogy mindezek ellenére mi összetartozunk. Magyarország, a magyar nemzet egy és oszthatatlan.\n"
                                  "Ezt az applikációt ki lehet kapcsolni, ha valaki előre látja, hogy\n"
                                  "a harangozás idején, zavarná az aktuális programjában. A telefon egy héttel, és később egy nappal a harangozást megelőzően még\n"
                                  "rákérdez a kikapcsolás szükségességére. Kérlek add tovább ennek az applikációnak hírét, hogy minél több honfitárunkkal együtt emlékezhessünk és emlékeztethessünk!\n\n"
                                  "Szilágyi Ákos – 56 Lángja Alapítvány\n"
                                  "osszharang.com",
                              style: TextStyle(fontSize: 16),
                            ),
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
    int hoursUntilAlarm = difference.inHours.remainder(24);
    int minutesUntilAlarm = difference.inMinutes.remainder(60);

    String countdownText;

    countdownText = "${daysUntilAlarm} nap ${hoursUntilAlarm} óra ${minutesUntilAlarm} perc múlva";


    return GestureDetector(
      //onTap: () => navigateToAlarmScreen(harangok[index]),
      child: Slidable(
        closeOnScroll: true,
        endActionPane: ActionPane(
          extentRatio: 0.4,
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.circular(12),
              onPressed: (context) {
                Alarm.stop(alarm.id);
                harangokBetoltese();
              },
              icon: Icons.delete_forever,
              backgroundColor: Colors.red.shade700,
            )
          ],
        ),
        child: Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 15,
                        color: daysUntilAlarm == 0 && hoursUntilAlarm == 0 && minutesUntilAlarm == 0
                            ? Colors.red
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/logo1.png',
                      fit: BoxFit.contain,
                    ),
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