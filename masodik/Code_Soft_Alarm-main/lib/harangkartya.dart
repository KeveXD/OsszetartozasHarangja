import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

Widget _buildHarangKartya(AlarmSettings alarm, int index) {
  TimeOfDay time = TimeOfDay.fromDateTime(alarm.dateTime);
  String formattedDate = DateFormat('EEEE, dd MMM', 'hu_HU').format(alarm.dateTime);
  return GestureDetector(

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