import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTANT: You must run `flutterfire configure` to generate the
// firebase_options.dart file and connect your app to Firebase.
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // We wrap initialization in a try-catch for cases where flutterfire configure 
  // hasn't been run yet, to prevent the app from completely crashing at startup.
  try {
    // If you have run flutterfire configure, uncomment the options line below:
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed. Did you run flutterfire configure? Error: $e");
  }
  
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase TODO App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// AuthWrapper listens to the authentication state.
// Routes users to TodoListScreen if logged in, or AuthScreen if not.
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
          return TodoListScreen(user: snapshot.data!); // User is logged in
        }
        return const AuthScreen(); // User is NOT logged in
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
              const Icon(Icons.lock, size: 100, color: Colors.teal),
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

// Displays the ToDo list and handles add/update/delete operations
class TodoListScreen extends StatelessWidget {
  final User user;
  TodoListScreen({super.key, required this.user});

  final TextEditingController _taskController = TextEditingController();

  Future<void> _addTask() async {
    final taskTitle = _taskController.text.trim();
    if (taskTitle.isEmpty) return;

    // Isolate user data by saving to: users/{uid}/todos
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .add({
      'title': taskTitle,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _taskController.clear();
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
        title: const Text('My TODOs'),
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
          // Input field for new tasks
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Enter new task...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _addTask(),
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
          ),
          
          // List of tasks
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('todos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Error loading tasks. Make sure Firebase is configured and Firestore rules allow read/write.",
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tasks yet. Add one above!', style: TextStyle(fontSize: 16)));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isDone = data['isDone'] ?? false;
                    
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
