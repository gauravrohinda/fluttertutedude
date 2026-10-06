import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

// Initialize the local notifications plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Timezones for scheduling notifications
  tz.initializeTimeZones();

  // Initialize Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

  // Initialize Firebase (Assuming google-services.json is configured manually on Android)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed. Make sure you configured Firebase. Error: $e");
  }
  
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO App with Reminders',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// AuthWrapper listens to the authentication state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return TodoListScreen(user: snapshot.data!); // Logged in
        }
        return const AuthScreen(); // Not logged in
      },
    );
  }
}

// Handles Email/Password Login and Sign Up
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_on, size: 100, color: Colors.deepPurple),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitAuth,
                    child: Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 18)),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin 
                    ? 'Don\'t have an account? Sign Up' 
                    : 'Already have an account? Login'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Displays the ToDo list and handles add/update/delete and Reminders
class TodoListScreen extends StatefulWidget {
  final User user;
  const TodoListScreen({super.key, required this.user});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  void _requestNotificationPermissions() async {
    // Request permissions for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _scheduleNotification(String title, DateTime scheduledTime, int id) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Task Reminder',
      body: 'Time to complete: $title',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'TODO Reminders',
          channelDescription: 'Notifications for scheduled TODO tasks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _addTask() async {
    final taskTitle = _taskController.text.trim();
    if (taskTitle.isEmpty) return;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('todos')
        .add({
      'title': taskTitle,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
      'reminderTime': _selectedDateTime?.toIso8601String(),
    });

    if (_selectedDateTime != null && _selectedDateTime!.isAfter(DateTime.now())) {
      // Use the last digits of the auto-generated ID or timestamp for a unique integer ID
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _scheduleNotification(taskTitle, _selectedDateTime!, notificationId);
    }

    _taskController.clear();
    setState(() {
      _selectedDateTime = null;
    });
  }

  Future<void> _toggleTaskStatus(DocumentSnapshot doc) async {
    await doc.reference.update({'isDone': !doc['isDone']});
  }

  Future<void> _deleteTask(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          // Input field and Reminder Picker
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                          hintText: 'Enter new task...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addTask,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notification_add, color: Colors.deepPurple),
                      onPressed: _pickDateTime,
                    ),
                    Text(
                      _selectedDateTime == null 
                        ? 'No reminder set' 
                        : 'Reminder: ${DateFormat('MMM dd, hh:mm a').format(_selectedDateTime!)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (_selectedDateTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                        onPressed: () => setState(() => _selectedDateTime = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // List of tasks
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user.uid)
                  .collection('todos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading tasks."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tasks yet. Add one with a reminder!'));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isDone = data['isDone'] ?? false;
                    final reminderTimeString = data['reminderTime'];
                    final reminderTime = reminderTimeString != null ? DateTime.parse(reminderTimeString) : null;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: Checkbox(
                          value: isDone,
                          onChanged: (_) => _toggleTaskStatus(doc),
                        ),
                        title: Text(
                          data['title'] ?? 'Untitled Task',
                          style: TextStyle(
                            fontSize: 16,
                            decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                            color: isDone ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: reminderTime != null
                            ? Text(
                                '⏰ ${DateFormat('MMM dd, hh:mm a').format(reminderTime)}',
                                style: TextStyle(color: reminderTime.isBefore(DateTime.now()) ? Colors.red : Colors.green),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteTask(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
