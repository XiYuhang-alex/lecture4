// 故意实验：串行 await vs Future.wait 并行
// 三个 1 秒延时任务，串行应约 3 秒，并行应约 1 秒

Future<void> task(String name) async {
  await Future.delayed(const Duration(seconds: 1));
  print('完成: $name');
}

Future<void> main() async {
  print('=== 故意实验：串行 vs 并行 ===\n');

  // 串行执行
  print('【串行 await 三个 1 秒任务】');
  final sw1 = Stopwatch()..start();
  await task('任务A');
  await task('任务B');
  await task('任务C');
  sw1.stop();
  print('串行耗时: ${sw1.elapsedMilliseconds} ms\n');

  // 并行执行
  print('【并行 Future.wait 三个 1 秒任务】');
  final sw2 = Stopwatch()..start();
  await Future.wait([
    task('任务A'),
    task('任务B'),
    task('任务C'),
  ]);
  sw2.stop();
  print('并行耗时: ${sw2.elapsedMilliseconds} ms\n');

  print('=== 结论 ===');
  print('串行耗时 ≈ 3000ms（三个任务依次等待）');
  print('并行耗时 ≈ 1000ms（三个任务同时等待）');
  print('→ Future.wait 让多个独立异步任务并行执行！');
}
