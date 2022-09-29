///board_rev.dart --- 获取板子的版本号
///通过读取saradc5的值来判断
///应该不需要root权限

import 'dart:io';

/// 0 -> A
/// 682 -> B
/// 1365 -> C
/// 2047 -> D
/// 2730 -> E
/// 3412 -> F
/// 4095 -> H // 原理图是这么写的
const Map levelVersionMap = {
  0: 'A',
  682: 'B',
  1365: 'C',
  2047: 'D',
  2730: 'E',
  3412: 'F',
  4095: 'H',
};

String? getBoardRev() {
  //不知为何读取这个dac时第一次读取的值不稳定，所以读取两次
  var processResult = Process.runSync(
      'cat', ['/sys/bus/iio/devices/iio:device0/in_voltage5_raw']);
  if (processResult.exitCode != 0) {
    return null;
  }
  sleep(Duration(milliseconds: 100));
  processResult = Process.runSync(
      'cat', ['/sys/bus/iio/devices/iio:device0/in_voltage5_raw']);
  if (processResult.exitCode != 0) {
    return null;
  }
  var value = int.parse(processResult.stdout.toString().trim());
  //找到最接近的值
  var min = 4095;
  var minKey = 0;
  levelVersionMap.forEach((key, v) {
    var diff = (key - value).abs();
    if (diff < min) {
      min = diff;
      minKey = key;
    }
  });
  return levelVersionMap[minKey];
}
