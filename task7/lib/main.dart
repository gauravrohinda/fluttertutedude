import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Roller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const DiceScreen(),
    );
  }
}

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  int diceNumber = 1;
  final Random random = Random();

  void rollDice() {
    setState(() {
      diceNumber = random.nextInt(6) + 1; // Generates a number from 1 to 6
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange[50],
      appBar: AppBar(
        title: const Text('Dice Roller App'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The dice visual represented using CustomPainter
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: DicePainter(diceNumber),
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: rollDice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Roll the Dice',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A custom painter to draw a dice face based on the current number
class DicePainter extends CustomPainter {
  final int number;

  DicePainter(this.number);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
      
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20), // Rounded corners for the dice
    );

    // Draw the dice background
    canvas.drawRRect(rrect, paint);
    // Draw the dice border
    canvas.drawRRect(rrect, borderPaint);

    final dotPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    
    // Dot positions
    final Offset center = Offset(w / 2, h / 2);
    final Offset topLeft = Offset(w * 0.25, h * 0.25);
    final Offset topRight = Offset(w * 0.75, h * 0.25);
    final Offset bottomLeft = Offset(w * 0.25, h * 0.75);
    final Offset bottomRight = Offset(w * 0.75, h * 0.75);
    final Offset middleLeft = Offset(w * 0.25, h * 0.5);
    final Offset middleRight = Offset(w * 0.75, h * 0.5);

    final double radius = w * 0.08; // Dot size

    void drawDot(Offset offset) {
      canvas.drawCircle(offset, radius, dotPaint);
    }

    // Draw dots based on the current dice number
    switch (number) {
      case 1:
        drawDot(center);
        break;
      case 2:
        drawDot(topLeft);
        drawDot(bottomRight);
        break;
      case 3:
        drawDot(topLeft);
        drawDot(center);
        drawDot(bottomRight);
        break;
      case 4:
        drawDot(topLeft);
        drawDot(topRight);
        drawDot(bottomLeft);
        drawDot(bottomRight);
        break;
      case 5:
        drawDot(topLeft);
        drawDot(topRight);
        drawDot(center);
        drawDot(bottomLeft);
        drawDot(bottomRight);
        break;
      case 6:
        drawDot(topLeft);
        drawDot(topRight);
        drawDot(middleLeft);
        drawDot(middleRight);
        drawDot(bottomLeft);
        drawDot(bottomRight);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) {
    return oldDelegate.number != number;
  }
}
