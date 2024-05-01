import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    initializeDateFormatting('hu', null); // Magyar nyelv beállítása
    _clockStreamController = StreamController<DateTime>();
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
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String formattedTime = DateFormat('HH:mm:ss', 'hu').format(snapshot.data!); // Magyar időzóna beállítása

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Magyar idő",
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(height: 10),
              Text(
                formattedTime,
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Magyar idő",
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(height: 10),
              Text(
                "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          );
        }
      },
    );
  }
}
