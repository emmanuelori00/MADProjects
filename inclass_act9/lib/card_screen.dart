import 'package:flutter/material.dart';

import 'card_record.dart';
import 'database_helper.dart';
import 'folder.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key, required this.helper, required this.folder});

  final DatabaseHelper helper;
  final Folder folder;

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  List<CardRecord> _cards = [];
  List<Folder> _folders = [];
  CardRecord? _selected;
  String _suit = 'Hearts';
  late int _folderId;
  bool _busy = true;
  String? _error;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _folderId = widget.folder.id!;
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _readCards() async {
    final folders = await widget.helper.getFoldersWithCounts();
    final cards = await widget.helper.getCards(widget.folder.id!);
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _cards = cards;
      _error = null;
    });
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _readCards();
    } catch (error, stack) {
      debugPrint('Card load failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = 'Could not load cards. Tap Refresh to retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _selected = null;
    _title.clear();
    _notes.clear();
    _suit = 'Hearts';
    _folderId = widget.folder.id!;
  }

  void _edit(CardRecord card) {
    if (_busy || _error != null) return;
    setState(() {
      _formKey.currentState?.reset();
      _selected = card;
      _title.text = card.title;
      _notes.text = card.notes;
      _suit = card.suit;
      _folderId = card.folderId;
      _feedback = 'Editing card ID ${card.id}';
    });
  }

  Future<void> _refreshAfterWrite(String message) async {
    try {
      await _readCards();
    } catch (error, stack) {
      debugPrint('Card refresh after write failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _error = '$message Refresh failed. Tap Refresh to retry.');
    }
  }

  Future<void> _save() async {
    if (_busy || _error != null || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final selected = _selected;
    final card = CardRecord(
      id: selected?.id,
      title: _title.text.trim(),
      suit: _suit,
      folderId: _folderId,
      notes: _notes.text,
      imageRef: selected?.imageRef,
    );
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final result = selected == null
          ? await widget.helper.insertCard(card)
          : await widget.helper.updateCard(card);
      if (!mounted) return;
      if (selected != null && result != 1) {
        final message = result == 0
            ? 'Card no longer exists. Updated 0 cards.'
            : 'Unexpected update result. Refresh the cards.';
        setState(() => _feedback = message);
        await _refreshAfterWrite(message);
        return;
      }
      final message = selected == null
          ? 'Saved card ID $result.'
          : 'Saved card ID ${selected.id}.';
      setState(() {
        _clearForm();
        _feedback = message;
      });
      await _refreshAfterWrite(message);
    } catch (error, stack) {
      debugPrint('Card save failed: $error\n$stack');
      if (!mounted) return;
      setState(
        () => _feedback = 'Could not save. Your input is kept; try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CardRecord card) async {
    if (_busy || _error != null) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete card?'),
          content: Text('Delete "${card.title}" (ID ${card.id})?'),
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
      final affected = await widget.helper.deleteCard(card.id!);
      if (!mounted) return;
      final message = affected == 1
          ? 'Deleted card ID ${card.id}.'
          : affected == 0
          ? 'Card no longer exists. Deleted 0 cards.'
          : 'Unexpected delete result. Refresh the cards.';
      setState(() {
        _feedback = message;
        if (affected == 1 && _selected?.id == card.id) _clearForm();
      });
      await _refreshAfterWrite(message);
    } catch (error, stack) {
      debugPrint('Card deletion failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _feedback = 'Could not delete the card. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _symbol(String suit) {
    switch (suit) {
      case 'Hearts':
        return '♥';
      case 'Diamonds':
        return '♦';
      case 'Clubs':
        return '♣';
      case 'Spades':
        return '♠';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !_busy && _error == null;
    final folderId = _folders.any((folder) => folder.id == _folderId)
        ? _folderId
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _selected == null
                      ? 'Add card'
                      : 'Edit card ID ${_selected!.id}',
                ),
                TextFormField(
                  controller: _title,
                  enabled: enabled,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter a card title.'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('suit-$_suit'),
                  initialValue: _suit,
                  decoration: const InputDecoration(labelText: 'Suit'),
                  items: CardRecord.suits
                      .map(
                        (suit) =>
                            DropdownMenuItem(value: suit, child: Text(suit)),
                      )
                      .toList(),
                  onChanged: enabled
                      ? (value) => setState(() => _suit = value!)
                      : null,
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey('folder-$folderId'),
                  initialValue: folderId,
                  decoration: const InputDecoration(labelText: 'Folder'),
                  items: _folders
                      .map(
                        (folder) => DropdownMenuItem(
                          value: folder.id,
                          child: Text(folder.name),
                        ),
                      )
                      .toList(),
                  onChanged: enabled
                      ? (value) => setState(() => _folderId = value!)
                      : null,
                  validator: (value) =>
                      value == null ? 'Choose an existing folder.' : null,
                ),
                TextFormField(
                  controller: _notes,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: enabled ? _save : null,
                  child: Text(_selected == null ? 'Add' : 'Save'),
                ),
                if (_selected != null)
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
            Text('Cards: ${_cards.length}'),
            if (_cards.isEmpty) const Text('No cards in this folder yet.'),
            for (final card in _cards)
              ListTile(
                leading: Text(
                  _symbol(card.suit),
                  style: const TextStyle(fontSize: 30),
                  semanticsLabel: '${card.suit} symbol',
                ),
                title: Text(card.title),
                subtitle: Text(
                  'ID ${card.id} · ${card.suit}'
                  '${card.notes.isEmpty ? '' : '\n${card.notes}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit card ${card.id}',
                      onPressed: () => _edit(card),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete card ${card.id}',
                      onPressed: () => _delete(card),
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
}
