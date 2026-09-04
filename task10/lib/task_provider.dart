import 'package:flutter/foundation.dart';
import 'task_model.dart';

class TaskProvider with ChangeNotifier {
  final List<TaskItem> _tasks = [];

  List<TaskItem> get tasks => [..._tasks];

  int get completedCount => _tasks.where((task) => task.isCompleted).length;
  int get totalCount => _tasks.length;

  void addTask(String title) {
    if (title.isEmpty) return;
    _tasks.add(
      TaskItem(
        id: DateTime.now().toString(),
        title: title,
      ),
    );
    notifyListeners();
  }

  void toggleTaskStatus(String id) {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex >= 0) {
      _tasks[taskIndex].toggleCompleted();
      notifyListeners();
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }
}
