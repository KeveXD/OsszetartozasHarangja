import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Realtime extends StatefulWidget {
  const Realtime({Key? key}) : super(key: key);

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
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          /*Positioned.fill(
            child: Image.asset(
              'assets/time.png', // A naptár ikon képe
              color: Colors.white.withOpacity(0.1), // Halvány szín
              fit: BoxFit.cover, // A kép kiterjesztése a teljes Stack méretére
            ),
          ),*/
          StreamBuilder<DateTime>(
            stream: _clockStreamController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                String formattedTime =
                DateFormat('HH:mm:ss', 'hu').format(snapshot.data!); // Magyar időzóna beállítása
                String formattedDate =
                DateFormat('yyyy. MM. dd.', 'hu').format(snapshot.data!); // Magyar dátum formázása

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 67),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${DateTime.now().year}. ${DateTime.now().month}. ${DateTime.now().day}.",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto', // Betűtípus beállítása
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.white.withOpacity(0.5),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
