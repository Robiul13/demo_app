import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class Task {
  String title;
  String? description;
  bool isDone;

  Task({required this.title, this.description, this.isDone = false});

  Map<String, dynamic> toMap() {
    return {'title': title, 'description': description, 'isDone': isDone};
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      description: map['description'],
      isDone: map['isDone'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _searchController = TextEditingController();
  List<Task> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? taskData = prefs.getString('tasks');
    if (taskData != null) {
      final List<dynamic> decoded = json.decode(taskData);
      setState(() {
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => Task.fromMap(e)));
        _filteredTasks = List.from(_tasks);
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_tasks.map((e) => e.toMap()).toList());
    await prefs.setString('tasks', encoded);
  }

  void _addTask(String title, String? desc) {
    setState(() {
      _tasks.add(Task(title: title, description: desc));
      _filteredTasks = List.from(_tasks);
    });
    _saveTasks();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task added')));
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _filteredTasks = List.from(_tasks);
    });
    _saveTasks();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  void _toggleDone(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
    _saveTasks();
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              _addTask(titleCtrl.text.trim(), descCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _filterTasks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = List.from(_tasks);
      } else {
        _filteredTasks = _tasks
            .where(
              (task) => task.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My To-Do List'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTasks,
              decoration: const InputDecoration(
                hintText: 'Search task...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? const Center(child: Text('No tasks yet'))
                : ListView.builder(
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (_) => _deleteTask(index),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 10,
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isDone,
                              onChanged: (_) => _toggleDone(task),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: task.description?.isNotEmpty == true
                                ? Text(task.description!)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
