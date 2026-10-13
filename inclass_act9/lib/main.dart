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
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  int _count = 0;
  int? _selectedId;
  bool _busy = true;
  String? _error;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _readRows() async {
    final rows = await widget.helper.queryAllRows();
    final count = await widget.helper.queryRowCount();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _count = count;
      _error = null;
    });
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _readRows();
    } catch (error, stackTrace) {
      debugPrint('Roster load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(
        () => _error = 'Could not load the roster. Tap Refresh to retry.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearForm() {
    _selectedId = null;
    _name.clear();
    _age.clear();
    _formKey.currentState?.reset();
  }

  void _edit(Map<String, dynamic> row) {
    if (_busy) return;
    setState(() {
      _formKey.currentState?.reset();
      _selectedId = row[DatabaseHelper.columnId] as int;
      _name.text = row[DatabaseHelper.columnName] as String;
      _age.text = '${row[DatabaseHelper.columnAge]}';
      _feedback = 'Editing ID $_selectedId';
    });
  }

  Future<void> _refreshAfterWrite(String result) async {
    try {
      await _readRows();
    } catch (error, stackTrace) {
      debugPrint('Refresh after write failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = '$result, but refresh failed. Tap Refresh to retry.';
      });
    }
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final selectedId = _selectedId;
    final row = <String, dynamic>{
      DatabaseHelper.columnName: _name.text.trim(),
      DatabaseHelper.columnAge: int.tryParse(_age.text.trim())!,
      DatabaseHelper.columnId: ?selectedId,
    };
    setState(() {
      _busy = true;
      _feedback = null;
      _error = null;
    });
    try {
      final result = selectedId == null
          ? await widget.helper.insert(row)
          : await widget.helper.update(row);
      if (!mounted) return;
      if (selectedId != null && result != 1) {
        final message = result == 0
            ? 'ID $selectedId no longer exists. Updated 0 rows.'
            : 'Unexpected update result: $result rows. Refresh the roster.';
        setState(() => _feedback = message);
        await _refreshAfterWrite(message);
        return;
      }
      final message = selectedId == null
          ? 'Saved guest with ID $result'
          : 'Saved ID $selectedId. Updated 1 row';
      setState(() {
        _clearForm();
        _feedback = message;
      });
      await _refreshAfterWrite(message);
    } catch (error, stackTrace) {
      debugPrint('Save failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(
        () => _feedback = 'Could not save. Your input is kept; try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    if (_busy) return;
    final id = row[DatabaseHelper.columnId] as int;
    // Guard the confirmation as well so no second action starts behind it.
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete guest?'),
          content: Text('Delete ID $id: ${row[DatabaseHelper.columnName]}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final deleted = await widget.helper.delete(id);
      if (!mounted) return;
      final message = deleted == 1
          ? 'Deleted ID $id. Deleted 1 row'
          : deleted == 0
          ? 'ID $id no longer exists. Deleted 0 rows.'
          : 'Unexpected delete result: $deleted rows. Refresh the roster.';
      setState(() {
        _feedback = message;
        _error = null;
        if (deleted == 1 && _selectedId == id) _clearForm();
      });
      await _refreshAfterWrite(message);
    } catch (error, stackTrace) {
      debugPrint('Delete failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _feedback = 'Could not delete. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fall Festival Roster')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_selectedId == null ? 'Add guest' : 'Edit ID $_selectedId'),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a name.' : null,
              ),
              TextFormField(
                controller: _age,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                validator: (value) {
                  final age = int.tryParse((value ?? '').trim());
                  return age == null || age < 0 || age > 130
                      ? 'Enter an integer age from 0 to 130.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: Text(_selectedId == null ? 'Add' : 'Save'),
              ),
              if (_selectedId != null)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _clearForm();
                          _feedback = 'Edit canceled. No changes saved.';
                        }),
                  child: const Text('Cancel edit'),
                ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _load,
          child: const Text('Refresh'),
        ),
        if (_feedback != null) Text(_feedback!),
        const SizedBox(height: 16),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text(_error!)
        else ...[
          Text('Record count: $_count'),
          const SizedBox(height: 16),
          if (_rows.isEmpty) const Text('No festival guests yet'),
          for (final row in _rows)
            ListTile(
              title: Text(
                'ID ${row[DatabaseHelper.columnId]}: '
                '${row[DatabaseHelper.columnName]}',
              ),
              subtitle: Text('Age: ${row[DatabaseHelper.columnAge]}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit ID ${row[DatabaseHelper.columnId]}',
                    onPressed: _busy ? null : () => _edit(row),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    tooltip: 'Delete ID ${row[DatabaseHelper.columnId]}',
                    onPressed: _busy ? null : () => _delete(row),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
        ],
      ],
    ),
  );
}
