import 'dart:convert';
import 'dart:io';

import 'package:async_json/book.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('=== async_json 图书统计 ===\n');

  // 异步读取 data/books.json
  final dataPath = p.join('data', 'books.json');
  final jsonString = await File(dataPath).readAsString();

  // JSON 解析为 List
  final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
  final List<Book> books =
      jsonList.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();

  // 1. 总数
  print('📚 图书总数: ${books.length}');

  // 2. 各类目数量统计
  final Map<String, int> categoryCount = {};
  for (final book in books) {
    categoryCount[book.category] = (categoryCount[book.category] ?? 0) + 1;
  }
  print('\n📂 各类目数量:');
  for (final entry in categoryCount.entries) {
    print('  ${entry.key}: ${entry.value}');
  }

  // 3. 借阅量 Top 3
  final sortedByBorrow = List<Book>.from(books)
    ..sort((a, b) => b.borrowCount.compareTo(a.borrowCount));
  print('\n🏆 借阅量 Top 3:');
  for (var i = 0; i < 3 && i < sortedByBorrow.length; i++) {
    final book = sortedByBorrow[i];
    print('  ${i + 1}. 《${book.title}》 (${book.category}) - ${book.borrowCount}次');
  }

  print('\n=== 统计完成 ===');
}
