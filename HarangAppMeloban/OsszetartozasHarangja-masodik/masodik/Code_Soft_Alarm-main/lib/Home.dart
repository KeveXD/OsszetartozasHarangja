import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cod_soft_alarm/Edit_page.dart';
import 'package:cod_soft_alarm/ring.dart';
import 'package:cod_soft_alarm/tobbi/editpagelogic.dart';
import 'package:cod_soft_alarm/tobbi/ido.dart';
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
        child: Column(
          children: [
            SizedBox(height: 100),
            Center(child: Realtime()),
            SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => navigateToAlarmScreen(null),
                  icon: Icon(Icons.add),
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
                          "Összetartozás harangja",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            EditPageLogic.createAndSaveAlarm();
                            //todo
                          },
                          child: Text(
                            "Blablabla",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHarangKartya(AlarmSettings alarm, int index) {
    TimeOfDay time = TimeOfDay.fromDateTime(alarm.dateTime);
    String formattedDate = DateFormat('EEEE, dd MMM', 'hu_HU').format(alarm.dateTime);
    return GestureDetector(
      onTap: () => navigateToAlarmScreen(harangok[index]),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(""),
              ListTile(
                splashColor: null,
                dense: true,
                minVerticalPadding: 10,
                horizontalTitleGap: 10,
                enabled: false,
                // onLongPress: () {
                //   // print("object");
                // },
                title: Row(
                  children: [
                    Text(
                      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ",
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.start,
                    ),
                    const Expanded(child: Text("")),
                    Text(formattedDate.toString()),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // const SlideTransitionExample()
            ],
          ),
        ),
      ),
    );
  }
}
