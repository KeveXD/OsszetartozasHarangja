import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';

class ExampleAlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const ExampleAlarmRingScreen({Key? key, required this.alarmSettings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Opacity(
            opacity: 0.3, // Átlátszóság beállítása
            child: Image.asset(
              'assets/logo2.jpg', // Háttérkép elérési útja
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Trianoni évforduló",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SwingAnimation(
                  child: Text("🔔", style: TextStyle(fontSize: 70)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    RawMaterialButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Biztosan le szeretné állítani a harangot?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Mégsem"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Alarm.stop(alarmSettings.id).then((_) => Navigator.pop(context));
                                  },
                                  child: Text("Igen"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        "Leállítás",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SwingAnimation extends StatefulWidget {
  final Widget child;

  const SwingAnimation({Key? key, required this.child}) : super(key: key);

  @override
  _SwingAnimationState createState() => _SwingAnimationState();
}

class _SwingAnimationState extends State<SwingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: -0.08, end: 0.08).animate(_controller),
      child: widget.child,
    );
  }
}
