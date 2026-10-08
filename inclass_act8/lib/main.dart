import 'package:flutter/material.dart';

import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper();
  try {
    await helper.init();
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Could not open local storage. Restart the app and check the logs.',
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(DirectoryApp(helper: helper));
}

class DirectoryApp extends StatelessWidget {
  const DirectoryApp({super.key, required this.helper});

  final DatabaseHelper helper;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fall Festival Roster',
    home: DirectoryScreen(helper: helper),
  );
}

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, required this.helper});

  final DatabaseHelper helper;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  List<Map<String, dynamic>> _rows = [];
  int _count = 0;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _count = count;
      });
    } catch (error, stackTrace) {
      debugPrint('Roster load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the roster. Tap Refresh to retry.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fall Festival Roster')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _busy ? null : _load,
            child: const Text('Refresh'),
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!)
          else ...[
            Text('Record count: $_count'),
            const SizedBox(height: 16),
            if (_rows.isEmpty)
              const Text('No festival guests yet')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    return ListTile(
                      title: Text(
                        'ID ${row[DatabaseHelper.columnId]}: '
                        '${row[DatabaseHelper.columnName]}',
                      ),
                      subtitle: Text('Age: ${row[DatabaseHelper.columnAge]}'),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
