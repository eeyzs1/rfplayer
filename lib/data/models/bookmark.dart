
class Bookmark {
  final String id;
  final String path;
  final String displayName;
  final DateTime createdAt;
  final int sortOrder;

  Bookmark({
    required this.id,
    required this.path,
    required this.displayName,
    required this.createdAt,
    required this.sortOrder,
  });

  factory Bookmark.fromDb(dynamic row) {
    return Bookmark(
      id: row.id,
      path: row.path,
      displayName: row.displayName,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      sortOrder: row.sortOrder,
    );
  }
}