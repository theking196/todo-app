import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider()..loadTasks(),
      child: MaterialApp(
        title: 'Todo App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const TodoScreen(),
      ),
    );
  }
}

class Todo {
  final String id;
  final String title;
  bool isCompleted;

  Todo({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'] ?? false,
      );
}

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;

  static const String _storageKey = 'todos';

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStrings = prefs.getStringList(_storageKey) ?? [];
    _todos = taskStrings.map((s) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(
        Uri.splitQueryString(s),
      );
      return Todo.fromJson(json);
    }).toList();
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStrings = _todos.map((t) {
      return Uri(queryParameters: t.toJson()).query;
    }).toList();
    await prefs.setStringList(_storageKey, taskStrings);
  }

  void addTask(String title) {
    final todo = Todo(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title);
    _todos.add(todo);
    _saveTasks();
    notifyListeners();
  }

  void toggleTask(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _todos.removeWhere((t) => t.id == id);
    _saveTasks();
    notifyListeners();
  }
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoProvider>().todos;
    final pending = todos.where((t) => !t.isCompleted).length;
    final completed = todos.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$pending pending, $completed done',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tasks yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add a task',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    context.read<TodoProvider>().deleteTask(todo.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${todo.title}" deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            context.read<TodoProvider>().addTask(todo.title);
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: CheckboxListTile(
                      value: todo.isCompleted,
                      onChanged: (_) {
                        context.read<TodoProvider>().toggleTask(todo.id);
                      },
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      secondary: Icon(
                        todo.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: todo.isCompleted ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<TodoProvider>().addTask(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<TodoProvider>().addTask(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}