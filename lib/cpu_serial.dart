import 'dart:io';

/// 读取/proc/cpuinfo的内容，并保留最后的Serial: xxxxxxxx
/// 应该不需要root权限
/// @return 返回cpu序列号, 如果没有找到则返回null
String? getCpuSerial() {
  var processResult = Process.runSync('cat', ['/proc/cpuinfo']);
  if (processResult.exitCode != 0) {
    return null;
  }
  var lines = processResult.stdout.toString().split('\n');
  var serial = lines.lastWhere((element) => element.startsWith('Serial'),
      orElse: () => '');
  if (serial.isEmpty) {
    return null;
  }
  return serial.split(':')[1].trim();
}
