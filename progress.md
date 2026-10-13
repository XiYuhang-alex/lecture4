# 进度报告4（第6周·Dart语言基础三：异步、异常与包管理）

> 仓库地址：https://github.com/XiYuhang-alex/lecture4

---

## 一、任务理解

本次作业完成了Dart异步编程、异常处理和包管理三个核心知识点的案例复现与自主实践。具体任务包括：

1. **案例复现** async_json 命令行工具：异步读取本地 JSON 数据文件，解析为 Dart 模型类，并输出统计汇总
2. **三步迭代开发**：从基础解析→统计输出→异常健壮性，每步一次 Git 提交
3. **故意实验**：验证串行 await 与 Future.wait 并行的性能差异
4. **选做任务**：JSON 字段缺失时的默认值处理机制

**验收标准**：
- 正常路径运行输出正确统计结果（总数、各类目数量、借阅量 Top3）
- 异常路径（文件缺失）输出友好提示而非崩溃堆栈
- Git 提交规范（每步一次提交，message 清晰）
- 仓库推送到 GitHub，包含完整历史

---

## 二、环境与工具

| 项目 | 详情 |
|------|------|
| 开发环境 | Dart SDK 3.13.2 (stable) |
| 操作系统 | Windows 11 x64 |
| 运行目标 | Dart VM（命令行应用） |
| 包管理 | Dart pub（国内镜像 pub.flutter-io.cn） |
| 版本控制 | Git 2.55.0 |
| AI辅助工具 | Trae AI（作为编程辅助，代码经本人验证后确认） |

---

## 三、过程记录

### 步骤一（准备阶段）
- `dart create async_json` 命令创建项目
- 确认 `pubspec.yaml` 中 path 依赖已配置
- 创建 `data/` 目录，编写 `books.json` 包含 15 条示例数据
- `git commit -m "feat: dataset & deps ready"`

### 步骤二（解析与统计）
- 创建 `lib/book.dart` 定义 Book 模型类
- 实现 `Book.fromJson` 工厂构造函数
- 重写 `bin/async_json.dart` 的 main 函数
- 异步读取 `data/books.json`，`jsonDecode` 解析
- 实现三类统计：总数、各类目数量 Map、借阅量排序 Top3
- 运行验证输出正确
- `git commit -m "feat: parse & stats from books.json"`

### 步骤三（异常处理增强）
- main 函数包裹 try-catch：FileSystemException 捕获文件缺失
- 内层 try-catch：FormatException 捕获 JSON 格式错误
- Book.fromJson 增加 null 安全处理：`??` 默认值
- 测试文件缺失：临时改名 books.json，验证友好提示
- 创建 `malformed_books.json` 测试缺失字段场景
- 创建 `test_malformed.dart` 验证默认值生效
- `git commit -m "feat: robust missing-field & file handling"`

### 故意实验
- 编写 `parallel_experiment.dart`
- 三个 Future.delayed(1秒) 任务
- 串行 await：耗时约 3028ms
- 并行 Future.wait：耗时约 1007ms
- `git commit -m "feat: add parallel experiment"`

### 推送与收尾
- `git push origin main` 推送到 GitHub
- 仓库地址：`git@github.com:XiYuhang-alex/lecture4.git`
- 4 次提交全部推送成功

---

## 四、关键代码

### 代码1：Book 模型类（含 fromJson/toJson 和步骤三增强的默认值处理）

```dart
// lib/book.dart
class Book {
  final String id;
  final String title;
  final String category;
  final int borrowCount;

  Book({required this.id, required this.title,
        required this.category, required this.borrowCount});

  /// 步骤三增强：缺失字段时提供默认值
  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: (j['id'] as String?) ?? '未知ID',
        title: (j['title'] as String?) ?? '未知书名',
        category: (j['category'] as String?) ?? '未分类',
        borrowCount: ((j['borrowCount'] as num?) ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'category': category,
        'borrowCount': borrowCount,
      };
}
```

**说明**：fromJson 使用 null-aware 操作符 (`??`) 和可空类型转换 (`as T?`)，当 JSON 字段缺失时自动使用默认值，避免崩溃。borrowCount 用 `(num?).toInt()` 同时兼容 int 和 double。  
**AI使用说明**：这段代码参考了实践指南提供的示例，由本人手工编写并验证通过。

### 代码2：main 函数异步读取 + 异常处理（步骤三完整版）

```dart
// bin/async_json.dart (核心片段)
void main() async {
  final dataPath = p.join('data', 'books.json');
  try {
    final jsonString = await File(dataPath).readAsString();
    late final List<Book> books;
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      books = jsonList.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    } on FormatException catch (e) {
      print('❌ JSON 格式错误: ${e.message}');
      return;
    } on TypeError catch (e) {
      print('❌ 数据类型错误: $e');
      return;
    }
    // ... 统计输出 ...
  } on FileSystemException {
    print('❌ 数据文件缺失，请检查$dataPath');
    exit(1);
  } catch (e) {
    print('❌ 未知错误: $e');
    exit(1);
  }
}
```

**说明**：双层 try-catch：外层捕获文件系统异常（路径错误、文件不存在），内层捕获 JSON 解析异常。await 等待文件读取但不阻塞事件循环。所有异常都输出友好提示，符合"红线：任何对外提供结果的程序不允许裸抛"的要求。  
**AI使用说明**：异常处理结构由本人根据指南要求手工设计并验证，各异常类型均测试覆盖。

### 代码3：故意实验 - 串行 vs 并行

```dart
// bin/parallel_experiment.dart
Future<void> main() async {
  // 串行
  final sw1 = Stopwatch()..start();
  await task('A'); await task('B'); await task('C');
  sw1.stop();
  print('串行耗时: ${sw1.elapsedMilliseconds} ms');  // ≈ 3000ms

  // 并行
  final sw2 = Stopwatch()..start();
  await Future.wait([task('A'), task('B'), task('C')]);
  sw2.stop();
  print('并行耗时: ${sw2.elapsedMilliseconds} ms');  // ≈ 1000ms
}
```

**说明**：直观验证 Future.wait 的并行效果：三个独立的 1 秒延时任务，串行执行约 3 秒，并行执行约 1 秒。这对第 11 课的并发网络请求有直接参考价值。

---

## 五、检查点结果

### （1）正常路径运行输出 ✅

命令：`dart run bin/async_json.dart`

```
=== async_json 图书统计 ===

📚 图书总数: 15

📂 各类目数量:
  计算机: 4
  文学: 4
  历史: 3
  经济: 2
  心理: 2

🏆 借阅量 Top 3:
  1. 《神雕侠侣》 (文学) - 445次
  2. 《三体》 (文学) - 342次
  3. 《明朝那些事儿》 (历史) - 312次

=== 统计完成 ===
```

✅ 检查点通过：总数正确、各类目分布正确、Top3 排序正确。

### （2）异常路径 - 文件缺失 ✅

操作：将 `data/books.json` 临时改名为 `books.json.bak` 后运行

```
=== async_json 图书统计 ===

❌ 数据文件缺失，请检查data\books.json
```

✅ 检查点通过：输出友好提示信息，exit code 1，无崩溃堆栈。恢复文件后正常路径仍可运行。

### （3）异常路径 - JSON 字段缺失 ✅

操作：使用 `malformed_books.json`（某些对象缺 borrowCount 或 id 字段）

```
原始JSON数据（缺失字段）:
  {id: B002, title: 缺失borrowCount的书, category: 测试}
  {id: B003, title: 缺失category和borrowCount}
  {title: 缺失id的书, category: 测试, borrowCount: 50}

解析后的Book对象（使用默认值）:
  Book{id: B002, title: 缺失borrowCount的书, category: 测试, borrowCount: 0}
  Book{id: B003, title: 缺失category和borrowCount, category: 未分类, borrowCount: 0}
  Book{id: 未知ID, title: 缺失id的书, category: 测试, borrowCount: 50}
```

✅ 检查点通过：缺失字段自动填充默认值，程序正常运行不崩溃。

### （4）故意实验 - 并行效果验证 ✅

```
串行耗时: 3028 ms   (预期 ≈ 3000ms)
并行耗时: 1007 ms   (预期 ≈ 1000ms)
```

✅ 实验结论：Future.wait 让多个独立异步任务并行执行，效率提升约 3 倍。

---

## 六、问题与调试

### 问题1：Dart SDK 版本不匹配
- **现象**：初次创建项目时报 pubspec.yaml sdk 约束不兼容
- **解决**：修改 `sdk: ^3.13.2` 匹配当前 Dart 版本

### 问题2：JSON 数字类型断言 TypeError
- **现象**：使用 `borrowCount as int` 时，若 JSON 数字为 double 则抛出 TypeError
- **解决**：改为 `(borrowCount as num).toInt()`，num 是 int/double 父类

### 问题3：字段缺失空指针崩溃
- **现象**：JSON 对象缺 borrowCount 时，`as num` 返回 null，后续 `.toInt()` 崩溃
- **解决**：改为 `((j['borrowCount'] as num?) ?? 0).toInt()`，null 安全 + 默认值

### 问题4：Windows 路径分隔符
- **现象**：手动拼接路径 `data/books.json` 在某些场景出错
- **解决**：统一使用 `path.join('data', 'books.json')` 跨平台处理

---

## 七、AI使用记录

| 用途 | 指令/需求摘要 | AI输出 | 本人验证方式 |
|------|---------------|--------|-------------|
| 项目创建指导 | Dart 项目创建的基本流程 | dart create 命令用法、目录结构说明 | 按指南执行 dart create，确认项目可运行 |
| 异常处理结构 | 如何为异步文件读取添加健壮的异常处理 | 双层 try-catch 结构，分别捕获 FileSystemException 和解析异常 | 分别测试文件缺失、格式错误场景，确认输出友好提示 |
| JSON 类型安全 | 如何安全地处理 JSON 中可能为 null 或类型不确定的字段 | 可空类型转换 (as T?) + null-aware 操作符 (??) | 创建 malformed_books.json 测试，确认默认值生效 |
| 并行实验设计 | 验证 Future.wait 并行效果的实验设计 | Stopwatch 计时 + 三个 1 秒 Future.delayed 对比 | 运行 parallel_experiment.dart，观测串行≈3s、并行≈1s |

---

## 八、证据截图与运行日志

### Git 提交历史（4 次提交，按步骤递进）
```
febbf8b feat: dataset & deps ready
6f4a239 feat: parse & stats from books.json
a385c73 feat: robust missing-field & file handling
83a3769 feat: add parallel experiment
```

### 正常路径运行日志
见 `evidence/normal_output.txt`

### 异常路径运行日志
见 `evidence/error_output.txt`

### 故意实验运行日志
见 `evidence/parallel_experiment.txt`

### 完整代码仓库
- GitHub: `git@github.com:XiYuhang-alex/lecture4.git`
- 路径: `lecture4/async_json/`

---

## 九、自评

| 评估项 | 完成情况 |
|--------|----------|
| async_json 案例复现（15分） | ✅ 完整完成。项目结构、Book模型、异步读取、统计输出全部实现 |
| 检查点验证（5分） | ✅ 四路检查点全部通过：正常路径、文件缺失、字段缺失、并行实验 |
| Git 规范（5分） | ✅ 4次提交，message 符合 Conventional Commits 规范，按步骤递进 |
| 报告记录（5分） | ✅ 进度报告十节完整填写，过程、代码、问题、证据齐全 |
| 异常处理红线 | ✅ 文件缺失友好提示、JSON解析错误捕获、字段缺失默认值，全部覆盖 |
| await 语义理解 | ✅ 能解释 await 在案例中的作用：等待文件读取但不阻塞事件循环 |

**总体自评**：本案例所有必做任务均已完成，代码经多次运行验证无误，Git提交规范完整，异常处理覆盖全面。

---

## 十、一句话收获与下一步计划

**一句话收获**：Dart 的 async/await 让异步代码写起来像同步一样直观，但要时刻记住 await 是"让出控制权"而非"阻塞线程"，Future.wait 是独立任务并行的利器。

**遗留问题**：Stream 的高级用法（如多订阅者、错误处理流）本次仅初步接触，课堂未深入；第11课网络请求会用到。

**下次课预习**：第11课网络编程 — dart:io HttpClient 或 http 包、API 调用、JSON 解析模型类复现 — 本课的 async/await + JSON + 模型类三件套直接复用。
