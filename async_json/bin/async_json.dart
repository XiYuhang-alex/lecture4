import 'dart:convert';
import 'dart:io';

import 'package:async_json/book.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('=== async_json 图书统计 ===\n');

  final dataPath = p.join('data', 'books.json');

  try {
    // 步骤三增强：精确捕获文件异常
    final jsonString = await File(dataPath).readAsString();

    late final List<Book> books;
    try {
      // JSON 解析
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      books =
          jsonList.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException catch (e) {
      print('❌ JSON 格式错误: ${e.message}');
      return;
    } on TypeError catch (e) {
      print('❌ 数据类型错误: $e');
      return;
    }

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
      print(
          '  ${i + 1}. 《${book.title}》 (${book.category}) - ${book.borrowCount}次');
    }

    print('\n=== 统计完成 ===');
  } on FileSystemException {
    print('❌ 数据文件缺失，请检查$dataPath');
    exit(1);
  } catch (e) {
    print('❌ 未知错误: $e');
    exit(1);
  }
}
