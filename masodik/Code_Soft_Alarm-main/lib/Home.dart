import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:cod_soft_alarm/Edit_page.dart';
import 'package:cod_soft_alarm/ring.dart';
import 'package:cod_soft_alarm/tobbi/ido.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late List<AlarmSettings> alarms;
  List<bool> _alarmOnOff = [];

  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }
    loadAlarms();
    subscription ??= Alarm.ringStream.stream.listen(
      (alarmSettings) => navigateToRingScreen(alarmSettings),
    );
  }

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      for (int i = 0; i < alarms.length; i++) {
        if (alarms[i].dateTime.year == 2050) {
          _alarmOnOff.add(false);
        } else {
          _alarmOnOff.add(true);
        }
      }
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings)  async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExampleAlarmRingScreen(alarmSettings: alarmSettings),
        ));
    loadAlarms();
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {

    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ExampleAlarmEditScreen(
                  alarmSettings: settings,
                )));

    if (res != null && res == true) loadAlarms();
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
          const SizedBox(height: 100),
          const Center(child: Realtime()),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => navigateToAlarmScreen(null),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          alarms.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      return _buildAlarmCard(alarms[index], index);
                    },
                  ),
                )
              : Expanded(
                  child: Center(
                    child: Text(
                      "Összetartozás harangja",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
        ],
      )),

    );
  }

  List<String> _hour(TimeOfDay time) {
    int hour = 0;
    String ampm = 'am';
    if (time.hour > 12) {
      hour = time.hour - 12;
      ampm = 'pm';
    } else if (time.hour == 0) {
      hour = 12;
    } else {
      hour = time.hour;
      ampm = 'am';
    }

    return [hour.toString().padLeft(2, '0'), ampm];
  }

  Widget _buildAlarmCard(AlarmSettings alarm, int index) {
    TimeOfDay time = TimeOfDay.fromDateTime(alarm.dateTime);
    String formattedDate = DateFormat('EEE, d MMM').format(alarm.dateTime);
    return GestureDetector(
      onTap: () => navigateToAlarmScreen(alarms[index]),
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
                  loadAlarms();
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
                      "${_hour(time)[0]}:${time.minute.toString().padLeft(2, '0')} ",
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.start,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(_hour(time)[1]),
                    ),
                    const Expanded(child: Text("")),
                    Text(formattedDate.toString()),
                  ],
                ),

                trailing: Switch(
                  value: _alarmOnOff[index],
                  onChanged: (bool value) {
                    if (value == false) {
                      Alarm.set(
                          alarmSettings: alarm.copyWith(
                              dateTime: alarm.dateTime.copyWith(year: 2050)));
                    } else {
                      Alarm.set(
                          alarmSettings: alarm.copyWith(
                              dateTime: alarm.dateTime
                                  .copyWith(year: DateTime.now().year)));
                    }
                    setState(() {
                      _alarmOnOff[index] = value;
                    });
                  },
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

