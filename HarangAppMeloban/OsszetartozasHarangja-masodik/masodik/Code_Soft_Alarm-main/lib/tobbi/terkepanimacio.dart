import 'package:flutter/material.dart';

class MapAnimation extends StatefulWidget {
  @override
  _MapAnimationState createState() => _MapAnimationState();
}

class _MapAnimationState extends State<MapAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: MediaQuery.of(context).size.width / 2, // Fél szélességű
              height: MediaQuery.of(context).size.height / 2, // Fél magasságú
              child: CustomPaint(
                painter: MapPainter(_animation.value),
                size: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2), // Fél méretű
              ),
            );
          },
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final double animationValue;

  MapPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Rajzoljuk ki a teljes térképet
    canvas.drawRect(Offset.zero & size, paint);

    // Szakítsuk szét kis részekre
    final rectWidth = size.width / 4;
    final rectHeight = size.height / 4;
    final offsetX = rectWidth / 2;
    final offsetY = rectHeight / 2;

    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        final left = rectWidth * i;
        final top = rectHeight * j;

        final path = Path()
          ..moveTo(left, top)
          ..lineTo(left + rectWidth, top)
          ..lineTo(left + rectWidth, top + rectHeight)
          ..lineTo(left, top + rectHeight)
          ..close();

        // Kis Magyarország régiók animációja
        final regionOffsetX = offsetX * animationValue;
        final regionOffsetY = offsetY * animationValue;

        final regionPath = Path()
          ..moveTo(left + regionOffsetX, top + regionOffsetY)
          ..lineTo(left + rectWidth - regionOffsetX, top + regionOffsetY)
          ..lineTo(left + rectWidth - regionOffsetX, top + rectHeight - regionOffsetY)
          ..lineTo(left + regionOffsetX, top + rectHeight - regionOffsetY)
          ..close();

        canvas.drawPath(regionPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
