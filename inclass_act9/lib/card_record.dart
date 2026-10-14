class CardRecord {
  static const suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

  final int? id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;

  const CardRecord({
    this.id,
    required this.title,
    required this.suit,
    this.notes = '',
    this.imageRef,
    required this.folderId,
  });

  factory CardRecord.fromMap(Map<String, dynamic> row) => CardRecord(
    id: row['id'] as int,
    title: row['title'] as String,
    suit: row['suit'] as String,
    notes: row['notes'] as String,
    imageRef: row['image_ref'] as String?,
    folderId: row['folder_id'] as int,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'suit': suit,
    'notes': notes,
    'image_ref': imageRef,
    'folder_id': folderId,
  };
}
