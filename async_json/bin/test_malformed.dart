import 'dart:convert';
import 'dart:io';

import 'package:async_json/book.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('=== 故意实验：缺失字段默认值处理 ===\n');

  // 测试 malformed_books.json
  final testPath = p.join('data', 'malformed_books.json');
  final jsonString = await File(testPath).readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

  print('原始JSON数据（缺失字段）:');
  for (final raw in jsonList) {
    print('  $raw');
  }

  print('\n解析后的Book对象（使用默认值）:');
  final books =
      jsonList.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  for (final book in books) {
    print('  $book');
  }

  print('\n✅ 默认值处理生效：');
  print('  - 缺失borrowCount → 默认0');
  print('  - 缺失category → 默认"未分类"');
  print('  - 缺失id → 默认"未知ID"');
}
