import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'folder.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({
    super.key,
    required this.helper,
    required this.guestScreen,
  });

  final DatabaseHelper helper;
  final Widget guestScreen;

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  List<Folder> _folders = [];
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
    super.dispose();
  }

  Future<void> _readFolders() async {
    final folders = await widget.helper.getFoldersWithCounts();
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _error = null;
    });
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _readFolders();
    } catch (error, stack) {
      debugPrint('Folder load failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = 'Could not load folders. Tap Refresh to retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshAfterWrite(String result) async {
    try {
      await _readFolders();
    } catch (error, stack) {
      debugPrint('Folder refresh after write failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = '$result Refresh failed. Tap Refresh to retry.');
    }
  }

  Future<void> _create() async {
    if (_busy || _error != null || !_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      await widget.helper.insertFolder(name);
      if (!mounted) return;
      final message = 'Created "$name".';
      setState(() {
        _name.clear();
        _formKey.currentState?.reset();
        _feedback = message;
      });
      await _refreshAfterWrite(message);
    } catch (error, stack) {
      debugPrint('Folder creation failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _feedback =
            error is DatabaseException && error.isUniqueConstraintError()
            ? 'That folder name already exists. Choose another name.'
            : 'Could not create the folder. Your name is kept; try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Folder folder) async {
    if (_busy || _error != null) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete folder?'),
          content: Text('Delete "${folder.name}" and all its cards?'),
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
      final affected = await widget.helper.deleteFolder(folder.id!);
      if (!mounted) return;
      final message = affected == 1
          ? 'Deleted "${folder.name}".'
          : affected == 0
          ? 'Folder no longer exists. Deleted 0 folders.'
          : 'Unexpected delete result. Refresh the folders.';
      setState(() => _feedback = message);
      await _refreshAfterWrite(message);
    } catch (error, stack) {
      debugPrint('Folder deletion failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _feedback = 'Could not delete the folder. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Folders'),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => widget.guestScreen),
                ),
          child: const Text('Guest roster'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy && _error == null,
                decoration: const InputDecoration(labelText: 'Folder name'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a folder name.'
                    : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy || _error != null ? null : _create,
                child: const Text('Create folder'),
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
        else if (_folders.isEmpty)
          const Text('No folders yet. Create one above.')
        else
          for (final folder in _folders)
            ListTile(
              title: Text(folder.name),
              subtitle: Text('Cards: ${folder.cardCount}'),
              trailing: IconButton(
                tooltip: 'Delete ${folder.name}',
                onPressed: () => _delete(folder),
                icon: const Icon(Icons.delete),
              ),
            ),
      ],
    ),
  );
}
