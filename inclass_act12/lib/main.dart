import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Autumn Product Manager',
      home: ProductPage(),
    ),
  );
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

String? priceRangeError(String minimum, String maximum) {
  final minText = minimum.trim();
  final maxText = maximum.trim();
  final min = double.tryParse(minText);
  final max = double.tryParse(maxText);
  if (minText.isNotEmpty && (min == null || !min.isFinite || min < 0)) {
    return 'Min price must be a finite number of zero or more.';
  }
  if (maxText.isNotEmpty && (max == null || !max.isFinite || max < 0)) {
    return 'Max price must be a finite number of zero or more.';
  }
  if (min != null && max != null && min > max) {
    return 'Min price cant be higher than max price.';
  }
  return null;
}

bool validProduct(Map<String, dynamic> data) {
  final name = data['name'];
  final price = data['price'];
  return name is String &&
      name.trim().isNotEmpty &&
      price is num &&
      price.isFinite &&
      price >= 0;
}

bool productMatches(
  Map<String, dynamic> data,
  String search,
  double? minimum,
  double? maximum,
) {
  if (!validProduct(data)) return false;
  final name = (data['name'] as String).trim().toLowerCase();
  final price = data['price'] as num;
  return name.contains(search.trim().toLowerCase()) &&
      (minimum == null || price >= minimum) &&
      (maximum == null || price <= maximum);
}

class _ProductPageState extends State<ProductPage> {
  final _products = FirebaseFirestore.instance.collection('products');
  late final _productStream = _products.snapshots();
  final _search = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _deleting = <String>{};

  @override
  void dispose() {
    _search.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _search.clear();
      _min.clear();
      _max.clear();
    });
  }

  Future<void> _createOrUpdate([
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) =>
          ProductEditor(products: _products, document: document),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this product?'),
        content: Text('ID: $id'),
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
    if (confirmed != true || !mounted) return;
    setState(() => _deleting.add(id));
    try {
      await _products.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product deleted.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed (${error.code}). Check your connection and permissions.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  Widget _productCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final price = data['price'] as num;
    final deleting = _deleting.contains(document.id);
    return Card(
      child: ListTile(
        title: Text(data['name'] as String),
        subtitle: Text(
          '${price.toStringAsFixed(2)}\nID: ${document.id}'
          '${deleting ? '\nDeleting...' : ''}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit product',
              icon: const Icon(Icons.edit),
              onPressed: deleting ? null : () => _createOrUpdate(document),
            ),
            IconButton(
              tooltip: 'Delete product',
              icon: const Icon(Icons.delete),
              onPressed: deleting ? null : () => _deleteProduct(document.id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterError = priceRangeError(_min.text, _max.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Autumn Product Manager')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(labelText: 'Search name'),
                  onChanged: (_) => setState(() {}),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _min,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Min price',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _max,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Max price',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                if (filterError != null)
                  Text(
                    filterError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Products could not load. Check connection and permissions.',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (filterError != null) {
                  return const Center(
                    child: Text('Fix the price range above.'),
                  );
                }
                final documents = snapshot.data!.docs;
                if (documents.isEmpty) {
                  return const Center(
                    child: Text('No products yet. Add one to begin.'),
                  );
                }
                final minimum = double.tryParse(_min.text.trim());
                final maximum = double.tryParse(_max.text.trim());
                final matches = documents.where(
                  (doc) => productMatches(
                    doc.data(),
                    _search.text,
                    minimum,
                    maximum,
                  ),
                );
                final invalid = documents.where(
                  (doc) => !validProduct(doc.data()),
                );
                return ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    if (matches.isEmpty)
                      const ListTile(title: Text('No products found')),
                    for (final document in matches) _productCard(document),
                    for (final document in invalid)
                      ListTile(
                        title: Text(
                          'Invalid product ${document.id}: check name/price types.',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create product',
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, required this.products, this.document});

  final CollectionReference<Map<String, dynamic>> products;
  final QueryDocumentSnapshot<Map<String, dynamic>>? document;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.document?.data()['name'] as String? ?? '',
  );
  late final _price = TextEditingController(
    text: widget.document?.data()['price']?.toString() ?? '',
  );
  var _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final data = <String, Object>{
      'name': _name.text.trim(),
      'price': double.parse(_price.text.trim()),
    };
    try {
      final document = widget.document;
      if (document == null) {
        await widget.products.add(data);
      } else {
        await widget.products.doc(document.id).update(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      debugPrint('Product save failed (${error.code}): ${error.message}');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Save failed (${error.code}). '
            'Check your connection and permissions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.document == null ? 'Create product' : 'Edit product',
                ),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a product name'
                      : null,
                ),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || !amount.isFinite || amount < 0
                        ? 'Enter a finite price of zero or more'
                        : null;
                  },
                ),
                if (_saveError != null)
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_saving)
                  const Text(
                    'Awaiting server acknowledgement. If offline, reconnect. '
                    'This editor stays open until the write succeeds or fails.',
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
