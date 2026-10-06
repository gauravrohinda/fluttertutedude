import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive & Adaptive App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ResponsiveHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResponsiveHomePage extends StatelessWidget {
  const ResponsiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // MediaQuery helps us get the screen size and orientation.
    // It's useful for high-level adaptive decisions.
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // Adaptive Drawer: Only show on screens smaller than 600px width (typical mobile screens)
      drawer: screenWidth < 600 ? const AppDrawer() : null,
      
      // LayoutBuilder allows us to build widgets based on their parent's constraints
      // rather than the overall screen size. This is essential for responsive design.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop / Large Tablet Layout (Width > 900)
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                const AppSideMenu(), // Persistent side menu
                Expanded(
                  flex: 3,
                  // More grid columns on larger screens
                  child: ContentArea(crossAxisCount: isLandscape ? 4 : 3),
                ),
                const Expanded(
                  flex: 1,
                  child: AdditionalInfoPanel(), // Extra information panel
                ),
              ],
            );
          } 
          // Tablet Layout (Width > 600 and <= 900)
          else if (constraints.maxWidth > 600) {
            return Row(
              children: [
                const AppSideMenu(), // Persistent side menu
                Expanded(
                  // Adjust columns based on orientation in tablet mode
                  child: ContentArea(crossAxisCount: isLandscape ? 3 : 2),
                ),
              ],
            );
          } 
          // Mobile Layout (Width <= 600)
          else {
            return ContentArea(crossAxisCount: isLandscape ? 2 : 1);
          }
        },
      ),
    );
  }
}

// Drawer used for smaller screens (Mobile)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'Menu', 
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(leading: Icon(Icons.home), title: Text('Home')),
          ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
          ListTile(leading: Icon(Icons.person), title: Text('Profile')),
        ],
      ),
    );
  }
}

// Side Menu used for larger screens (Tablet and Desktop)
class AppSideMenu extends StatelessWidget {
  const AppSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.deepPurple.shade50,
      child: Column(
        children: const [
          SizedBox(height: 20),
          ListTile(leading: Icon(Icons.home), title: Text('Home')),
          ListTile(leading: Icon(Icons.dashboard), title: Text('Dashboard')),
          ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
          ListTile(leading: Icon(Icons.person), title: Text('Profile')),
        ],
      ),
    );
  }
}

// Main Content Area displaying a responsive Grid
class ContentArea extends StatelessWidget {
  final int crossAxisCount;

  const ContentArea({super.key, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      // GridView automatically handles layout within the available space 
      // without overflowing, adapting to the given crossAxisCount.
      child: GridView.builder(
        itemCount: 20,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 4 / 3, // Ensures items maintain shape across sizes
        ),
        itemBuilder: (context, index) {
          return Card(
            color: Colors.deepPurple[100],
            elevation: 2,
            child: Center(
              child: Text(
                'Item $index',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Additional information panel visible only on very large screens
class AdditionalInfoPanel extends StatelessWidget {
  const AdditionalInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Details', 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'This side panel is visible on large screens to display extra information without cluttering the main view.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Responsive design adapts the UI to fit different screen sizes gracefully.',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
