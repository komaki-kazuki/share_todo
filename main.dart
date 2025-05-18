import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '時間割アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  static List<Widget> _widgetOptions = <Widget>[
    CalendarScreen(),
    TodoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'ToDoリスト',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<String> weekdays = ['月', '火', '水', '木', '金', '土'];
  final int periods = 6;

  final Map<String, Color> subjectColors = {
    '国語': Colors.red.shade100,
    '数学': Colors.blue.shade100,
    '英語': Colors.green.shade100,
    '理科': Colors.yellow.shade100,
    '社会': Colors.orange.shade100,
    '体育': Colors.purple.shade100,
    '音楽': Colors.pink.shade100,
    '美術': Colors.teal.shade100,
    '技術': Colors.brown.shade100,
    '家庭': Colors.cyan.shade100,
  };

  List<List<Map<String, String>>> timetable = List.generate(
    6,
    (_) => List.generate(6, (_) => {'subject': '', 'teacher': ''}),
  );

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _saveTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(timetable);
    await prefs.setString('timetable', jsonString);
  }

  Future<void> _loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('timetable');
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      setState(() {
        timetable = decoded.map<List<Map<String, String>>>(
          (row) => (row as List).map<Map<String, String>>(
            (cell) => Map<String, String>.from(cell),
          ).toList(),
        ).toList();
      });
    }
  }

  void _editCell(int period, int day) {
    final TextEditingController subjectController = TextEditingController(text: timetable[period][day]['subject']);
    final TextEditingController teacherController = TextEditingController(text: timetable[period][day]['teacher']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${weekdays[day]}曜日 ${period + 1}限'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: InputDecoration(labelText: '授業名'),
              ),
              TextField(
                controller: teacherController,
                decoration: InputDecoration(labelText: '教授名'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  timetable[period][day]['subject'] = subjectController.text;
                  timetable[period][day]['teacher'] = teacherController.text;
                });
                await _saveTimetable();
                Navigator.pop(context);
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('カレンダー')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Table(
          border: TableBorder.all(),
          columnWidths: {
            0: FixedColumnWidth(40),
          },
          children: [
            TableRow(
              children: [
                Container(), // Left-top empty cell
                ...weekdays.map((day) => Container(
                  color: Colors.lightBlue.shade100,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )).toList(),
              ],
            ),
            for (int period = 0; period < periods; period++)
              TableRow(
                children: [
                  Container(
                    height: 80,
                    color: Colors.lightGreen.shade100,
                    alignment: Alignment.center,
                    child: Text('${period + 1}限'),
                  ),
                  for (int day = 0; day < weekdays.length; day++)
                    Builder(
                      builder: (context) {
                        String subject = timetable[period][day]['subject'] ?? '';
                        Color bgColor = subjectColors[subject] ?? Colors.white;
                        return GestureDetector(
                          onTap: () => _editCell(period, day),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    timetable[period][day]['subject'] ?? '',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    timetable[period][day]['teacher'] ?? '',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<Map<String, dynamic>> _todoList = [];

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _saveTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _todoList.map((todo) {
      return {
        'content': todo['content'],
        'deadline': (todo['deadline'] as DateTime).toIso8601String(),
        'done': todo['done'] ?? false,
      };
    }).toList();
    await prefs.setString('todoList', jsonEncode(jsonList));
  }

  Future<void> _loadTodoList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('todoList');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _todoList.clear();
        _todoList.addAll(jsonList.map((item) {
          return {
            'content': item['content'],
            'deadline': DateTime.parse(item['deadline']),
            'done': item['done'] ?? false,
          };
        }));
      });
    }
  }

  void _showAddTodoDialog() {
    final TextEditingController contentController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('ToDoを追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(labelText: '内容'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime now = DateTime.now();
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 1),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(selectedDate == null
                        ? '期限を選択'
                        : '期限: ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () async {
                    final content = contentController.text.trim();
                    if (content.isNotEmpty && selectedDate != null) {
                      setState(() {
                        _todoList.add({
                          'content': content,
                          'deadline': selectedDate,
                          'done': false,
                        });
                      });
                      await _saveTodoList();
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeTodo(int index) async {
    setState(() {
      _todoList.removeAt(index);
    });
    await _saveTodoList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDoリスト'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'ToDo追加',
            onPressed: _showAddTodoDialog,
          ),
        ],
      ),
      body: _todoList.isEmpty
          ? Center(child: Text('ToDoがありません'))
          : ListView.builder(
              itemCount: _todoList.length,
              itemBuilder: (context, index) {
                final todo = _todoList[index];
                final deadline = todo['deadline'] as DateTime;
                return ListTile(
                  leading: Checkbox(
                    value: todo['done'] ?? false,
                    onChanged: (bool? value) async {
                      setState(() {
                        todo['done'] = value ?? false;
                      });
                      await _saveTodoList();
                    },
                  ),
                  title: Text(
                    todo['content'],
                    style: TextStyle(
                      decoration: (todo['done'] ?? false)
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: Text(
                    '期限: ${deadline.year}/${deadline.month}/${deadline.day}',
                    style: TextStyle(
                      decoration: (todo['done'] ?? false)
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeTodo(index),
                  ),
                );
              },
            ),
    );
  }
}
