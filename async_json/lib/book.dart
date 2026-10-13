class Book {
  final String id;
  final String title;
  final String category;
  final int borrowCount;

  Book({
    required this.id,
    required this.title,
    required this.category,
    required this.borrowCount,
  });

  /// 步骤三增强：缺失字段时提供默认值，避免 null 断言错误
  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: (j['id'] as String?) ?? '未知ID',
        title: (j['title'] as String?) ?? '未知书名',
        category: (j['category'] as String?) ?? '未分类',
        borrowCount: ((j['borrowCount'] as num?) ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'borrowCount': borrowCount,
      };

  @override
  String toString() =>
      'Book{id: $id, title: $title, category: $category, borrowCount: $borrowCount}';
}
