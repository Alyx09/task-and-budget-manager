import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:task_and_budget_manager/deadline_notification_service.dart';

// Hive imports
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DeadlineNotificationService.initialize();
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();

  // Open a box (database) where data will be stored
  await Hive.openBox('tasks');
  
  // Initialize notification service
  await DeadlineNotificationService.initialize();
  
  // Request notification permissions (Android 13+)
  final bool permissionGranted = await DeadlineNotificationService.requestPermissions();
  print('Notification permission granted: $permissionGranted');
  
  // Optionally send a test notification to verify everything works
  if (permissionGranted) {
    await DeadlineNotificationService.showTestNotification();
  }

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task & Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const HomePage(),
    );
  }
}



// -------------------- HOME PAGE --------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int remainingTasks = 0;
  
  @override
  void initState() {
    super.initState();
    _loadInitialTaskCount();
  }
  
  // Load initial task count when app starts
  Future<void> _loadInitialTaskCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks_general');
    if (storedTasks != null && storedTasks.isNotEmpty) {
      try {
        List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(json.decode(storedTasks));
        setState(() {
          remainingTasks = tasks.where((task) => !task['completed']).length;
        });
      } catch (e) {
        print("Error loading initial task count: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Task Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  image: DecorationImage(
                    image: AssetImage('assets/images/pattern.png'),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$remainingTasks tasks remaining',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.purple),
                title: const Text(
                  'Home',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.task, color: Colors.purple),
                title: const Text(
                  'Tasks',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TaskDetailPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.purple),
                title: const Text(
                  'Calendar',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Hello there,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  'Ready to be productive?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Task count summary card with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.task_alt,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remaining Tasks',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$remainingTasks',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Button to navigate to task detail page
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          onTaskCountChanged: (count) {
                            setState(() {
                              remainingTasks = count;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
  }
}













class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _allTasks = [];
  bool _isLoading = true;
  final Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllTasks();
  }

  Future<void> _loadAllTasks() async {
    setState(() {
      _isLoading = true;
    });
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? generalTasks = prefs.getString('tasks_general');
    if (generalTasks != null && generalTasks.isNotEmpty) {
      try {
        setState(() {
          _allTasks = List<Map<String, dynamic>>.from(json.decode(generalTasks));
          _buildEventsList();
          _isLoading = false;
        });
      } catch (e) {
        print("Error decoding general tasks: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildEventsList() {
    _events.clear();
    for (var task in _allTasks) {
      if (task['completed'] == true) continue;
      
      DateTime taskDate = DateTime.parse(task['date']);
      DateTime normalizedDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
      
      if (!_events.containsKey(normalizedDate)) {
        _events[normalizedDate] = [];
      }
      
      String taskTime = DateFormat('hh:mm a').format(taskDate);
      _events[normalizedDate]!.add('${task['name']} - $taskTime');
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  void _addTaskAndUpdateCalendar(Map<String, dynamic> newTask) {
    setState(() {
      _allTasks.add(newTask);
      _allTasks.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
      _buildEventsList();
    });
    _saveTasks();
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks_general', json.encode(_allTasks));
  }

  void _removeTaskFromCalendar(Map<String, dynamic> taskToRemove) {
    setState(() {
      _allTasks.removeWhere((task) =>
          task['name'] == taskToRemove['name'] && task['date'] == taskToRemove['date']);
      _buildEventsList();
    });
    _saveTasks();
  }

  void _editTaskAndUpdateCalendar(Map<String, dynamic> oldTask, Map<String, dynamic> newTask) {
    setState(() {
      int index = _allTasks.indexWhere((task) =>
          task['name'] == oldTask['name'] && task['date'] == oldTask['date']);
      if (index != -1) {
        _allTasks[index] = newTask;
        _allTasks.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
        _buildEventsList();
      }
    });
    _saveTasks();
  }

  void _deleteTaskAndUpdateCalendar(Map<String, dynamic> taskToDelete) {
    setState(() {
      _allTasks.removeWhere((task) =>
          task['name'] == taskToDelete['name'] && task['date'] == taskToDelete['date']);
      _buildEventsList();
    });
    _saveTasks();
  }

  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    return _allTasks.where((task) {
      DateTime taskDate = DateTime.parse(task['date']);
      String taskFormattedDay = DateFormat('yyyy-MM-dd').format(taskDate);
      return taskFormattedDay == formattedDay && task['completed'] != true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple.shade700,
        elevation: 0,
        actions: const [
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.shade700,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      headerStyle: HeaderStyle(
                        titleTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        formatButtonTextStyle: const TextStyle(color: Colors.white),
                        formatButtonDecoration: BoxDecoration(
                          color: Colors.purple.shade500,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.white70),
                        holidayTextStyle: const TextStyle(color: Colors.white),
                        todayDecoration: BoxDecoration(
                          color: Colors.purple.shade400,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(color: Colors.purple.shade700),
                        markerDecoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.white),
                        weekendStyle: TextStyle(color: Colors.white70),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showTaskDetailsDialog(context, _getTasksForDay(selectedDay), selectedDay);
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      eventLoader: _getEventsForDay,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Upcoming Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailPage(
                                selectedDate: DateTime.now(),
                                onTaskAdded: _addTaskAndUpdateCalendar,
                                onTaskRemoved: _deleteTaskAndUpdateCalendar,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _allTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first task',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildUpcomingTasksList(),
                ),
              ],
            ),
      
     
    );
  }

  Widget _buildUpcomingTasksList() {
    // Sort and filter tasks - only show upcoming non-completed tasks
    final now = DateTime.now();
    final upcomingTasks = _allTasks
        .where((task) => 
            DateTime.parse(task['date']).isAfter(now) && 
            task['completed'] != true)
        .toList()
      ..sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    // Group tasks by date
    Map<String, List<Map<String, dynamic>>> groupedTasks = {};
    for (var task in upcomingTasks) {
      final taskDate = DateTime.parse(task['date']);
      final key = DateFormat('yyyy-MM-dd').format(taskDate);
      
      if (!groupedTasks.containsKey(key)) {
        groupedTasks[key] = [];
      }
      groupedTasks[key]!.add(task);
    }

    if (upcomingTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No upcoming tasks',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTasks.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTasks.keys.elementAt(index);
        final tasksForDate = groupedTasks[dateKey]!;
        final taskDate = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDateHeader(taskDate),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300),
                  ),
                ],
              ),
            ),
            ...tasksForDate.map((task) => _buildTaskCard(task)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE, MMM d').format(date);
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final taskDate = DateTime.parse(task['date']);
    final taskTime = DateFormat('hh:mm a').format(taskDate);
    
    // Determine if task is priority
    final isPriority = task['priority'] == 'high';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPriority
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          _showEditTaskDialog(context, task);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPriority ? Colors.red.shade50 : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPriority ? Icons.priority_high : Icons.event_note,
                  color: isPriority ? Colors.red.shade700 : Colors.purple.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (task['description'] != null && task['description'].isNotEmpty)
                      Text(
                        task['description'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          taskTime,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        if (task['category'] != null && task['category'].isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              task['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showTaskOptionsMenu(context, task);
                },
                color: Colors.grey.shade600,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskOptionsMenu(BuildContext context, Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTaskDialog(context, task);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                ),
                title: const Text('Mark Complete'),
                onTap: () {
                  Navigator.pop(context);
                  _markTaskComplete(task);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red.shade700,
                ),
                title: const Text('Delete Task'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTask(context, task);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _markTaskComplete(Map<String, dynamic> task) {
    Map<String, dynamic> updatedTask = Map<String, dynamic>.from(task);
    updatedTask['completed'] = true;
    _editTaskAndUpdateCalendar(task, updatedTask);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task marked as complete'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            updatedTask['completed'] = false;
            _editTaskAndUpdateCalendar(updatedTask, updatedTask);
          },
        ),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTaskAndUpdateCalendar(task);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
  // Get task details
  final taskName = task['name'];
  final taskDate = DateTime.parse(task['date']);
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TaskDetailPage(
        selectedDate: taskDate,
        onTaskAdded: (newTask) {
          // Remove the old task first
          _removeTaskFromCalendar(task);
          // Then add the new/updated task
          _addTaskAndUpdateCalendar(newTask);
        },
        onTaskRemoved: _deleteTaskAndUpdateCalendar,
      ),
    ),
  );
  
  // You might want to pre-fill the task details by passing some initial values
  // This depends on how TaskDetailPage is implemented
  // If possible, modify TaskDetailPage to accept an optional initial task
}

  void _showTaskDetailsDialog(BuildContext context, List<Map<String, dynamic>> tasks, DateTime selectedDate) {
    if (tasks.isEmpty) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No tasks scheduled for this day',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          selectedDate: selectedDate,
                          onTaskAdded: _addTaskAndUpdateCalendar,
                          onTaskRemoved: _deleteTaskAndUpdateCalendar,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Divider(color: Colors.grey.shade300),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length + 1, // +1 for the add button at the end
                      itemBuilder: (context, index) {
                        if (index == tasks.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailPage(
                                      selectedDate: selectedDate,
                                      onTaskAdded: _addTaskAndUpdateCalendar,
                                      onTaskRemoved: _deleteTaskAndUpdateCalendar,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Task'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return _buildTaskCard(tasks[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }
}




class TaskDetailPage extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(Map<String, dynamic>)? onTaskAdded;
  final Function(Map<String, dynamic>)? onTaskRemoved;
  final Function(int)? onTaskCountChanged;

  const TaskDetailPage({
    super.key, 
    this.selectedDate, 
    this.onTaskAdded, 
    this.onTaskRemoved,
    this.onTaskCountChanged
  });

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<Map<String, dynamic>> tasks = [];
  List<String> lists = [];
  TextEditingController taskController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  bool isCompletedTasksVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // App theme colors
  final Color primaryColor = const Color(0xFF6A1B9A); // Deep Purple 800
  final Color secondaryColor = const Color(0xFFD1C4E9); // Deep Purple 100
  final Color accentColor = const Color(0xFF4A148C); // Deep Purple 900
  final Color backgroundColor = const Color(0xFFF3E5F5); // Deep Purple 50
  
  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      selectedDate = widget.selectedDate!;
    }
    _loadTasks();
    _loadLists();
    
    // Initialize animation controller for the completed tasks drawer
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    taskController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  void _updateTaskCount() {
    if (widget.onTaskCountChanged != null) {
      int activeTaskCount = tasks.where((task) => task['completed'] == false).length;
      widget.onTaskCountChanged!(activeTaskCount);
    }
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks_general');
    if (storedTasks != null && storedTasks.isNotEmpty) {
      try {
        setState(() {
          tasks = List<Map<String, dynamic>>.from(json.decode(storedTasks));
          _updateTaskCount(); // Update task count after loading
        });
      } catch (e) {
        print("Error decoding tasks: $e");
      }
    } else {
      _updateTaskCount(); // Also call when no tasks are found
    }
  }

  Future<void> _loadLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLists = prefs.getString('my_lists');
    if (storedLists != null && storedLists.isNotEmpty) {
      setState(() {
        lists = List<String>.from(json.decode(storedLists));
      });
    }
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_general', json.encode(tasks));
  }

  void _toggleTaskCompleted(int index) {
    setState(() {
      tasks[index]['completed'] = !tasks[index]['completed'];
      _saveTasks();
      _updateTaskCount(); // Update task count after completion toggle
    });
  }

  void _toggleCompletedTasksVisibility() {
    setState(() {
      isCompletedTasksVisible = !isCompletedTasksVisible;
      if (isCompletedTasksVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showCalendar(String taskName, String subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Date for "$taskName"',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
              markersMaxCount: 3,
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                selectedDate = selectedDay;
              });
              Navigator.pop(context);
              _showTimePicker(taskName, subject);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(String taskName, String subject) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        DateTime combinedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        String formattedDateTime = combinedDateTime.toIso8601String();
        Map<String, dynamic> newTask = {
          "name": taskName,
          "subject": subject,
          "date": formattedDateTime,
          "completed": false,
          "subtasks": [], // Initialize subtasks as empty list
          "priority": "medium", // Add default priority
          "reminder": false, // Add reminder flag
        };
        tasks.add(newTask);
        tasks.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
        _saveTasks();
        if (widget.onTaskAdded != null) {
          widget.onTaskAdded!(newTask);
        }
        _updateTaskCount(); // Update task count after adding new task
        
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task added successfully'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      });
    }
  }

  void _addTask() {
    taskController.clear();
    subjectController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add New Task',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                hintText: 'Enter subject name',
                prefixIcon: Icon(Icons.category, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: secondaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                hintText: 'Enter task name',
                prefixIcon: Icon(Icons.task_alt, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: secondaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskController.text.isNotEmpty && subjectController.text.isNotEmpty) {
                String taskName = taskController.text;
                String subject = subjectController.text;
                Navigator.pop(context);
                _showCalendar(taskName, subject);
              } else {
                // Show validation error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter both subject and task name'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    DateTime date = DateTime.parse(isoDate);
    return DateFormat('EEE, MMM d, h:mm a').format(date);
  }

  // Get priority color
  Color _getPriorityColor(String priority) {
    switch(priority.toLowerCase()) {
      case 'high':
        return Colors.red[700]!;
      case 'medium':
        return Colors.orange[700]!;
      case 'low':
        return Colors.green[700]!;
      default:
        return Colors.orange[700]!;
    }
  }

  Widget buildTaskItem(Map<String, dynamic> task) {
    // Get time remaining until task due date
    DateTime taskDate = DateTime.parse(task['date']);
    Duration timeRemaining = taskDate.difference(DateTime.now());
    bool isOverdue = timeRemaining.isNegative && task['completed'] == false;
    
    // Get task priority (default to medium if not set)
    String priority = task['priority'] ?? 'medium';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue ? Colors.red : Colors.transparent,
          width: isOverdue ? 1 : 0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              task['completed'] == true ? Colors.grey[100]! : secondaryColor.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: task['completed'] == true ? Colors.green : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: task['completed'] == true ? Colors.green : primaryColor,
                width: 2,
              ),
            ),
            child: Checkbox(
              value: task['completed'] == true,
              onChanged: (value) {
                setState(() {
                  task['completed'] = value ?? false;
                  _saveTasks();
                  _updateTaskCount(); // Update task count when checkbox changes
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              fillColor: WidgetStateProperty.resolveWith((states) {
                return Colors.transparent;
              }),
              checkColor: Colors.white,
              shape: const CircleBorder(),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task['name'],
                  style: TextStyle(
                    decoration: task['completed'] == true ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600,
                    color: task['completed'] == true ? Colors.grey : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
              if (task['reminder'] == true)
                Icon(Icons.notifications_active, size: 16, color: primaryColor),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task['subject'],
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(priority),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task['date']),
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (task['subtasks']?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.checklist, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${task['subtasks'].where((st) => st['completed'] == true).length}/${task['subtasks'].length} subtasks completed',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskViewPage(task: task),
              ),
            ).then((_) {
              // Refresh the task list when returning from TaskViewPage
              _loadTasks();
            });
          },
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: primaryColor),
            onSelected: (String selectedOption) {
              switch (selectedOption) {
                case 'Edit':
                  _editTask(task);
                  break;
                case 'Delete':
                  _deleteTask(task);
                  break;
                case 'Priority':
                  _changePriority(task);
                  break;
                case 'Reminder':
                  _toggleReminder(task);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Priority',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text('Set Priority'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Reminder',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(task['reminder'] == true ? 'Remove Reminder' : 'Set Reminder'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changePriority(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Priority'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPriorityOption(task, 'High', Colors.red[700]!),
              _buildPriorityOption(task, 'Medium', Colors.orange[700]!),
              _buildPriorityOption(task, 'Low', Colors.green[700]!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityOption(Map<String, dynamic> task, String priority, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          task['priority'] = priority.toLowerCase();
          _saveTasks();
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.flag, color: color),
            const SizedBox(width: 16),
            Text(
              priority,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReminder(Map<String, dynamic> task) {
    setState(() {
      task['reminder'] = !(task['reminder'] ?? false);
      _saveTasks();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(task['reminder'] == true ? 'Reminder set' : 'Reminder removed'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _editTask(Map<String, dynamic> task) {
    TextEditingController taskNameController = TextEditingController(text: task['name']);
    TextEditingController taskSubjectController = TextEditingController(text: task['subject']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Task',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskNameController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  prefixIcon: Icon(Icons.task_alt, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: taskSubjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.category, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: secondaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskNameController.text.isNotEmpty && taskSubjectController.text.isNotEmpty) {
                  setState(() {
                    task['name'] = taskNameController.text;
                    task['subject'] = taskSubjectController.text;
                  });
                  _saveTasks();
                  Navigator.pop(context);
                  
                  // Show success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task updated successfully'),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Task?'),
          content: Text('Are you sure you want to delete "${task['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks.remove(task);
                  _saveTasks();
                  if (widget.onTaskRemoved != null) {
                    widget.onTaskRemoved!(task);
                  }
                  _updateTaskCount(); // Update task count after deletion
                });
                Navigator.pop(context);
                
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Task deleted'),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate tasks into active and completed
    List<Map<String, dynamic>> activeTasks = tasks.where((task) => task['completed'] == false).toList();
    List<Map<String, dynamic>> completedTasks = tasks.where((task) => task['completed'] == true).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addTask,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              backgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with date and task count
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activeTasks.length} Active Tasks',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Active tasks section
            Expanded(
              child: activeTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active tasks',
                            style: TextStyle(
                              fontSize: 20,
                              color: primaryColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add a task',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addTask,
                            icon: const Icon(Icons.add),
                            label: const Text('Add a task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: activeTasks.length,
                      itemBuilder: (context, index) {
                        return buildTaskItem(activeTasks[index]);},
                      ),
            ),
            
            // Completed tasks section header
            InkWell(
              onTap: _toggleCompletedTasksVisibility,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AnimatedRotation(
                          turns: isCompletedTasksVisible ? 0.25 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.arrow_right,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed Tasks',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${completedTasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Animated container for completed tasks
            SizeTransition(
              sizeFactor: _animation,
              child: Container(
                color: backgroundColor,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: completedTasks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No completed tasks yet',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        shrinkWrap: true,
                        itemCount: completedTasks.length,
                        itemBuilder: (context, index) {
                          return buildTaskItem(completedTasks[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New custom widget for animated task item deletion (optional addition)
class AnimatedTaskItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;
  
  const AnimatedTaskItem({
    required this.child,
    required this.onDismissed,
    super.key,
  });
  
  @override
  _AnimatedTaskItemState createState() => _AnimatedTaskItemState();
}

class _AnimatedTaskItemState extends State<AnimatedTaskItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleDismiss() {
    _controller.forward().then((_) {
      widget.onDismissed();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: ReverseAnimation(_animation),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _handleDismiss(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

// Optional extension: Task Statistics Widget (can be added to the TaskDetailPage)
class TaskStatisticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Color primaryColor;
  final Color secondaryColor;
  
  const TaskStatisticsWidget({
    required this.tasks,
    required this.primaryColor,
    required this.secondaryColor,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    int totalTasks = tasks.length;
    int completedTasks = tasks.where((task) => task['completed']).length;
    int activeTasks = totalTasks - completedTasks;
    double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
    
    // Count tasks by priority
    int highPriorityTasks = tasks.where((task) => 
      (task['priority'] ?? 'medium').toLowerCase() == 'high' && !task['completed']).length;
    int mediumPriorityTasks = tasks.where((task) => 
      (task['priority'] ?? 'medium').toLowerCase() == 'medium' && !task['completed']).length;
    int lowPriorityTasks = tasks.where((task) => 
      (task['priority'] ?? 'medium').toLowerCase() == 'low' && !task['completed']).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(totalTasks.toString(), 'Total', Icons.assignment, primaryColor),
              _buildStatItem(activeTasks.toString(), 'Active', Icons.timer, Colors.orange),
              _buildStatItem(completedTasks.toString(), 'Done', Icons.check_circle, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Completion Rate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: secondaryColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${completionRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tasks by Priority',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityItem('High', highPriorityTasks, Colors.red[700]!),
              const SizedBox(width: 8),
              _buildPriorityItem('Medium', mediumPriorityTasks, Colors.orange[700]!),
              const SizedBox(width: 8),
              _buildPriorityItem('Low', lowPriorityTasks, Colors.green[700]!),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriorityItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class TaskViewPage extends StatefulWidget {
  final Map<String, dynamic> task;
  
  const TaskViewPage({super.key, required this.task});
  
  @override
  _TaskViewPageState createState() => _TaskViewPageState();
}

class _TaskViewPageState extends State<TaskViewPage> {
  final TextEditingController _subtaskController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  @override
  void initState() {
    super.initState();
    // Ensure subtasks is initialized
    if (widget.task['subtasks'] == null) {
      widget.task['subtasks'] = [];
    }
  }
  
  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks_general');
    if (storedTasks != null) {
      List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(json.decode(storedTasks));
      int taskIndex = tasks.indexWhere((t) =>
          t['name'] == widget.task['name'] && t['date'] == widget.task['date']);
      if (taskIndex != -1) {
        tasks[taskIndex] = widget.task;
        await prefs.setString('tasks_general', json.encode(tasks));
      }
    }
  }
  
  void _navigateToBudgetPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskBudgetPage(
          taskName: widget.task['name'],
          taskId: widget.task['date'], // Using date as unique identifier
        ),
      ),
    );
  }
  
  void _showAddSubtaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Subtask',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        content: TextField(
          controller: _subtaskController,
          decoration: InputDecoration(
            hintText: 'Enter subtask name',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.task_alt, color: Colors.purple),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_subtaskController.text.isNotEmpty) {
                String subtaskName = _subtaskController.text;
                _subtaskController.clear();
                Navigator.pop(context);
                _showCalendar(subtaskName);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
  
  void _showEditSubtaskDialog(int index) {
    Map<String, dynamic> subtask = widget.task['subtasks'][index];
    _subtaskController.text = subtask['name'];
    _selectedDate = DateTime.parse(subtask['date']);
    _selectedTime = TimeOfDay(
      hour: _selectedDate.hour,
      minute: _selectedDate.minute,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Subtask',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        content: TextField(
          controller: _subtaskController,
          decoration: InputDecoration(
            hintText: 'Enter subtask name',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.edit, color: Colors.purple),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _subtaskController.clear();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_subtaskController.text.isNotEmpty) {
                String subtaskName = _subtaskController.text;
                _subtaskController.clear();
                Navigator.pop(context);
                _showCalendarForEdit(subtaskName, index);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
  
  void _deleteSubtask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Subtask',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.task['subtasks'][index]['name']}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.task['subtasks'].removeAt(index);
                _saveTasks();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showCalendar(String subtaskName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Date for "$subtaskName"',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        content: Container(
          width: 300,
          // Removed fixed height to prevent overflow
          constraints: const BoxConstraints(maxHeight: 350),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                  Navigator.pop(context);
                  _showTimePicker(subtaskName);
                },
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
  
  void _showCalendarForEdit(String subtaskName, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Date for "$subtaskName"',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        content: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 350),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                  Navigator.pop(context);
                  _showTimePickerForEdit(subtaskName, index);
                },
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
  
  void _showTimePicker(String subtaskName) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        DateTime combinedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        Map<String, dynamic> newSubtask = {
          'name': subtaskName,
          'completed': false,
          'date': combinedDateTime.toIso8601String(),
          'lastModified': DateTime.now().toIso8601String(),
        };
        widget.task['subtasks'].add(newSubtask);
        _saveTasks();
      });
    }
  }
  
  void _showTimePickerForEdit(String subtaskName, int index) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        DateTime combinedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // Update the existing subtask
        widget.task['subtasks'][index]['name'] = subtaskName;
        widget.task['subtasks'][index]['date'] = combinedDateTime.toIso8601String();
        widget.task['subtasks'][index]['lastModified'] = DateTime.now().toIso8601String();
        
        _saveTasks();
      });
    }
  }
  
  void _toggleSubtaskCompleted(int index) {
    setState(() {
      widget.task['subtasks'][index]['completed'] =
          !widget.task['subtasks'][index]['completed'];
      _saveTasks();
    });
  }
  
  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period";
  }
  
  Widget _buildLastModifiedText(Map<String, dynamic> subtask) {
    if (subtask.containsKey('lastModified')) {
      final lastModified = DateTime.parse(subtask['lastModified']);
      final hour = lastModified.hour > 12 ? lastModified.hour - 12 : lastModified.hour == 0 ? 12 : lastModified.hour;
      final period = lastModified.hour >= 12 ? 'PM' : 'AM';
      return Text(
        "Last modified: ${lastModified.day}/${lastModified.month}/${lastModified.year} at ${hour.toString().padLeft(2, '0')}:${lastModified.minute.toString().padLeft(2, '0')} $period",
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return const SizedBox.shrink();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Top gradient area with budget button
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple, Colors.deepPurple],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(
                    widget.task['completed'] 
                      ? Icons.check_circle 
                      : Icons.pending_actions,
                    size: 45,
                    color: widget.task['completed'] 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task['completed'] ? "Completed" : "In Progress",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Budget button - redesigned
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _navigateToBudgetPage,
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text(
                      'Task Budget',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Subtasks header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtasks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddSubtaskDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Subtasks list
          Expanded(
            child: (widget.task['subtasks'] as List).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_late,
                        size: 70,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subtasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the "Add" button to create a subtask',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: (widget.task['subtasks'] as List).length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> subtask = widget.task['subtasks'][index];
                    bool isCompleted = subtask['completed'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isCompleted ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              subtask['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateTime(subtask['date']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _buildLastModifiedText(subtask),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditSubtaskDialog(index),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSubtask(index),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            onTap: () {
                              _toggleSubtaskCompleted(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}











class TaskBudgetPage extends StatefulWidget {
  final String taskName;
  final String taskId;

  const TaskBudgetPage({
    super.key,
    required this.taskName,
    required this.taskId,
  });

  @override
  _TaskBudgetPageState createState() => _TaskBudgetPageState();
}

class _TaskBudgetPageState extends State<TaskBudgetPage> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> income = [];
  List<Map<String, dynamic>> savings = [];
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemQuantityController = TextEditingController();
  TextEditingController itemAmountController = TextEditingController();
  TextEditingController savingsGoalController = TextEditingController();
  TextEditingController savingsNoteController = TextEditingController();
  bool isLoading = true;
  bool showAllExpenses = false;
  bool autoUseSavings = true; // Always true by default

  @override
  void initState() {
    super.initState();
    _loadTaskBudget();
  }

  Future<void> _loadTaskBudget() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String expenseKey = 'task_expenses_${widget.taskId}';
    String incomeKey = 'task_income_${widget.taskId}';
    String savingsKey = 'task_savings_${widget.taskId}';

    String? expensesJson = prefs.getString(expenseKey);
    String? incomeJson = prefs.getString(incomeKey);
    String? savingsJson = prefs.getString(savingsKey);

    setState(() {
      expenses = expensesJson != null
          ? List<Map<String, dynamic>>.from(json.decode(expensesJson))
          : [];
      income = incomeJson != null
          ? List<Map<String, dynamic>>.from(json.decode(incomeJson))
          : [];
      savings = savingsJson != null
          ? List<Map<String, dynamic>>.from(json.decode(savingsJson))
          : [];
      isLoading = false;
    });
  }

  Future<void> _saveTaskBudget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String expenseKey = 'task_expenses_${widget.taskId}';
    String incomeKey = 'task_income_${widget.taskId}';
    String savingsKey = 'task_savings_${widget.taskId}';

    await prefs.setString(expenseKey, json.encode(expenses));
    await prefs.setString(incomeKey, json.encode(income));
    await prefs.setString(savingsKey, json.encode(savings));
  }

  /// Calculate Total Budget (Sum of all incomes)
  double _calculateTotalBudget() {
    return income.fold(0, (sum, item) => sum + (item['amount'] as double));
  }

  /// Calculate Total Expenses
  double _calculateTotalExpenses() {
    return expenses.fold(0, (sum, item) {
      double amount = item['amount'] as double;
      int quantity = item['quantity'] as int? ?? 1;
      return sum + (amount * quantity);
    });
  }

  /// Calculate Total Savings
  double _calculateTotalSavings() {
    return savings.fold(0, (sum, item) => sum + (item['amount'] as double));
  }

  /// Calculate Remaining Budget (Total Budget - Total Expenses)
  double _calculateRemainingBudget() {
    return _calculateTotalBudget() - _calculateTotalExpenses();
  }

  /// Calculate Available Funds (Including Savings if enabled)
  double _calculateAvailableFunds() {
    double regularBudget = _calculateRemainingBudget();

    // If regular budget is enough, just return it
    if (regularBudget >= 0) {
      return regularBudget;
    }

    // If regular budget is depleted and autoUseSavings is enabled,
    // include savings in available funds
    if (autoUseSavings) {
      return regularBudget + _calculateTotalSavings();
    }

    return regularBudget;
  }

  /// Calculate how much of the savings is being used
  double _calculateSavingsUsed() {
    double regularBudget = _calculateRemainingBudget();

    // If regular budget is positive, no savings are being used
    if (regularBudget >= 0) {
      return 0;
    }

    // If auto use savings is enabled, calculate how much savings is being used
    if (autoUseSavings) {
      double savingsUsed = -regularBudget; // Convert negative budget to positive savings used
      return savingsUsed > _calculateTotalSavings() ? _calculateTotalSavings() : savingsUsed;
    }

    return 0;
  }

  /// Calculate Remaining Savings after potential usage
  double _calculateRemainingSavings() {
    return _calculateTotalSavings() - _calculateSavingsUsed();
  }

  /// Check if budget is sufficient and show improved warning if not
Future<bool> _checkBudgetSufficiency() async {
  double remainingBudget = _calculateRemainingBudget();
  
  // If budget is sufficient, return true immediately
  if (remainingBudget >= 0) {
    return true;
  }
  
  // If budget insufficient but no savings available, show improved warning and return false
  if (_calculateTotalSavings() <= 0) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 48,
        ),
        title: const Text(
          'Budget Shortfall',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your budget is insufficient for this task',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Consider these options:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSuggestionRow(
              Icons.add_circle,
              Colors.green,
              'Add more budget to your task'
            ),
            const SizedBox(height: 8),
            _buildSuggestionRow(
              Icons.savings,
              Colors.blue,
              'Create a savings fund for emergencies'
            ),
            const SizedBox(height: 8),
            _buildSuggestionRow(
              Icons.edit,
              Colors.orange,
              'Reduce your planned expenses'
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Clear input fields
              itemNameController.clear();
              itemAmountController.clear();
              itemQuantityController.clear();
              Navigator.pop(context);
            },
            // Other styling...
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red),
              ),
              elevation: 0,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
    return false;
  }
  
  // If budget insufficient but savings available, ask if user wants to use savings with improved UI
  bool useSavings = false;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.savings,
        color: Colors.amber,
        size: 48,
      ),
      title: const Text(
        'Use Your Savings?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.amberAccent,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your budget is insufficient',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.amber.shade200),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Would you like to use your savings to cover this expense?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            useSavings = false;
            // Clear input fields
            itemNameController.clear();
            itemAmountController.clear();
            itemQuantityController.clear();
            Navigator.pop(context);
          },
          child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            useSavings = true;
            setState(() {
              autoUseSavings = true;
            });
            // Clear input fields
            itemNameController.clear();
            itemAmountController.clear();
            itemQuantityController.clear();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Use Savings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );
  
  return useSavings;
}

// Helper method to build suggestion rows
Widget _buildSuggestionRow(IconData icon, Color color, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    ],
  );
}


  void _addItem(String type) {
    if (type == 'savings') {
      _addSavings();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == 'income' ? 'Add Budget' : 'Add Expense',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: itemNameController,
              decoration: InputDecoration(
                labelText: type == 'income' ? 'Source Name' : 'Expense Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  type == 'income' ? Icons.account_balance : Icons.shopping_cart,
                  color: type == 'income' ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (type == 'expense')
              TextField(
                controller: itemQuantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers, color: Colors.blue),
                ),
                keyboardType: TextInputType.number,
              ),
            if (type == 'expense') const SizedBox(height: 16),
            TextField(
              controller: itemAmountController,
              decoration: InputDecoration(
                labelText: type == 'income'
                    ? 'Amount'
                    : 'Amount (for one unit)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_exchange, color: Colors.amber),
                prefixText: '₱ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear all input fields when canceling
              itemNameController.clear();
              itemAmountController.clear();
              itemQuantityController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (itemNameController.text.isEmpty || itemAmountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields.')),
                );
                return;
              }

              // For income, just add it directly
              if (type == 'income') {
                setState(() {
                  income.add({
                    'name': itemNameController.text,
                    'amount': double.parse(itemAmountController.text),
                  });
                  _saveTaskBudget();
                });
                itemNameController.clear();
                itemAmountController.clear();
                Navigator.pop(context);
                return;
              }

              // For expense, we need to check budget first
              // Calculate the proposed expense amount
              double expenseAmount = double.parse(itemAmountController.text);
              int expenseQuantity = int.tryParse(itemQuantityController.text) ?? 1;
              double totalExpenseAmount = expenseAmount * expenseQuantity;
              
              // Temporarily add the expense to check if budget would be sufficient
              Map<String, dynamic> newExpense = {
                'name': itemNameController.text,
                'quantity': expenseQuantity,
                'amount': expenseAmount,
              };
              
              // Calculate current remaining budget
              double currentRemaining = _calculateRemainingBudget();
              
              // Check if adding this expense would exceed budget
              if (currentRemaining >= totalExpenseAmount) {
                // Budget is sufficient, add the expense
                setState(() {
                  expenses.add(newExpense);
                  _saveTaskBudget();
                });
                itemNameController.clear();
                itemAmountController.clear();
                itemQuantityController.clear();
                Navigator.pop(context);
              } else {
                // Budget is insufficient, close the add dialog first
                Navigator.pop(context);
                
                // Check if savings are available
                double availableSavings = _calculateTotalSavings();
                double deficit = totalExpenseAmount - currentRemaining;
                
                if (availableSavings <= 0) {
                  // No savings available, show warning
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'Budget Warning',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      content: const Text(
                        'You do not have enough budget to proceed with this expense. Please add more budget or reduce the expense amount.',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            // Clear all input fields
                            itemNameController.clear();
                            itemAmountController.clear();
                            itemQuantityController.clear();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Check if savings are enough to cover the deficit
                  if (deficit > availableSavings) {
                    // Savings not enough to cover deficit
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Insufficient Funds',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You do not have enough funds to cover this expense.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Your budget and savings combined are not sufficient for this expense.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              // Clear all input fields
                              itemNameController.clear();
                              itemAmountController.clear();
                              itemQuantityController.clear();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Savings are enough, ask if user wants to use them
                    bool useSavings = false;
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Budget Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You do not have enough budget for this expense.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Would you like to use your savings to cover the deficit?',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              useSavings = false;
                              // Clear all input fields
                              itemNameController.clear();
                              itemAmountController.clear();
                              itemQuantityController.clear();
                              Navigator.pop(context);
                            },
                            child: const Text('No', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              useSavings = true;
                              setState(() {
                                autoUseSavings = true;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Yes, Use Savings'),
                          ),
                        ],
                      ),
                    );
                    
                    // Only add the expense if user agrees to use savings
                    if (useSavings) {
                      setState(() {
                        expenses.add(newExpense);
                        _saveTaskBudget();
                      });
                      itemNameController.clear();
                      itemAmountController.clear();
                      itemQuantityController.clear();
                    }
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'income' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }



  

  void _addSavings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Savings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: savingsNoteController,
              decoration: InputDecoration(
                labelText: 'Savings Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.savings, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: itemAmountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_exchange, color: Colors.amber),
                prefixText: '₱ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: savingsGoalController,
              decoration: InputDecoration(
                labelText: 'Goal (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.flag, color: Colors.green),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (savingsNoteController.text.isNotEmpty &&
                  itemAmountController.text.isNotEmpty) {
                setState(() {
                  savings.add({
                    'description': savingsNoteController.text,
                    'amount': double.parse(itemAmountController.text),
                    'goal': savingsGoalController.text.isEmpty
                         ? null
                         : savingsGoalController.text,
                    'date': DateTime.now().toString(),
                  });
                  _saveTaskBudget();
                });
                savingsNoteController.clear();
                itemAmountController.clear();
                savingsGoalController.clear();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Method to handle action that requires budget check
  Future<void> proceedWithAction() async {
    bool hasSufficientBudget = await _checkBudgetSufficiency();
    
    if (hasSufficientBudget) {
      // Proceed with the action
      // Example: Navigate to next step, save data, etc.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proceeding with action...')),
      );
    } else {
      // Action canceled due to insufficient funds
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action canceled due to insufficient funds')),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    double totalBudget = _calculateTotalBudget();
    double totalExpenses = _calculateTotalExpenses();
    double totalSavings = _calculateTotalSavings();
    double regularRemainingBudget = _calculateRemainingBudget();
    double savingsUsed = _calculateSavingsUsed();
    double remainingSavings = _calculateRemainingSavings();
    double availableFunds = _calculateAvailableFunds();
    
    // Calculate percentage for progress bar based on available funds (including savings)
    double totalAvailableFunds = totalBudget + totalSavings;
    double fundPercentage = totalAvailableFunds > 0 
        ? (availableFunds / totalAvailableFunds * 100) 
        : 0;
    
    // Determine how many expenses to display
    final displayExpenses = showAllExpenses 
        ? expenses 
        : expenses.take(3).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget for: ${widget.taskName}'),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
        : SafeArea(
            child: Column(
              children: [
                // Budget Summary Card at the top
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        availableFunds >= 0 
                            ? Colors.green.shade100 
                            : Colors.red.shade100,
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              availableFunds >= 0 
                                  ? Icons.account_balance_wallet 
                                  : Icons.warning_amber_rounded,
                              size: 30,
                              color: availableFunds >= 0 
                                  ? Colors.green.shade800 
                                  : Colors.red.shade800,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Available Funds',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: availableFunds >= 0 
                                    ? Colors.green.shade800 
                                    : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₱${availableFunds.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: availableFunds >= 0 
                                ? Colors.green.shade700 
                                : Colors.red.shade700,
                          ),
                        ),
                        
                        // Show savings usage if any savings are being used
                        if (savingsUsed > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade300)
                            ),
                            child: Text(
                              'Using ₱${savingsUsed.toStringAsFixed(2)} from savings',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: fundPercentage > 0 ? fundPercentage / 100 : 0,
                            backgroundColor: Colors.grey.shade300,
                            color: availableFunds >= 0 
                                ? Colors.green 
                                : Colors.red,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Budget column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Budget',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '₱${totalBudget.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    if (regularRemainingBudget < 0)
                                      Icon(
                                        Icons.warning,
                                        size: 16,
                                        color: Colors.amber.shade700,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Savings column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Savings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₱${remainingSavings.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: savingsUsed > 0 
                                        ? Colors.blue.shade600
                                        : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Expenses column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Expenses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₱${totalExpenses.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                
                // Expense list header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${expenses.length} items',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (expenses.length > 3) // Only show toggle if we have more than 3 expenses
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  showAllExpenses = !showAllExpenses;
                                });
                              },
                              child: Text(
                                showAllExpenses ? 'View Less' : 'View All',
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Expenses List with limited view
                Expanded(
                  child: expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the buttons below to add expenses',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: displayExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = displayExpenses[index];
                            final totalItemCost = expense['amount'] * expense['quantity'];
                            final originalIndex = expenses.indexOf(expense);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                title: Text(
                                  expense['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      '₱${expense['amount'].toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                    const Text(' × '),
                                    Text(
                                      '${expense['quantity']}',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₱${totalItemCost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          expenses.removeAt(originalIndex);
                                          _saveTaskBudget();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Savings summary (collapsible panel)
                if (savings.isNotEmpty)
                  ExpansionTile(
                    title: Row(
                      children: [
                        const Text(
                          'Saved Amounts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        if (savingsUsed > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'In Use',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    leading: const Icon(Icons.savings, color: Colors.blue),
                    children: savings.map((saving) {
                      return ListTile(
                        title: Text(saving['description']),
                        subtitle: saving['goal'] != null 
                            ? Text('Goal: ${saving['goal']}') 
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₱${saving['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  savings.remove(saving);
                                  _saveTaskBudget();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                
                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_card),
                          label: const Text('Add Budget'),
                          onPressed: () => _addItem('income'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.savings),
                          label: const Text('Add Savings'),
                          onPressed: () => _addItem('savings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.receipt_long),
                          label: const Text('Add Expense'),
                          onPressed: () => _addItem('expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}