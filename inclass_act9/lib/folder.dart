class Folder {
  final int? id;
  final String name;
  final String createdAt;
  final int cardCount;

  const Folder({
    this.id,
    required this.name,
    required this.createdAt,
    this.cardCount = 0,
  });

  factory Folder.fromMap(Map<String, dynamic> row) => Folder(
    id: row['id'] as int,
    name: row['name'] as String,
    createdAt: row['created_at'] as String,
    cardCount: row['card_count'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'created_at': createdAt,
  };
}
