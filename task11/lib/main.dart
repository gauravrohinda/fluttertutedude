import 'package:flutter/material.dart';
import 'animated_container_screen.dart';
import 'animated_opacity_screen.dart';
import 'animation_controller_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animations Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Screens'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuCard(
            context,
            'Animated Container',
            'Smoothly animate container properties like color and size.',
            Icons.crop_square,
            const AnimatedContainerScreen(),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            'Animated Opacity',
            'Fade a widget in and out smoothly.',
            Icons.opacity,
            const AnimatedOpacityScreen(),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            'Animation Controller',
            'Use an AnimationController to spin a widget.',
            Icons.settings_backup_restore,
            const AnimationControllerScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Widget targetScreen) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        },
      ),
    );
  }
}
