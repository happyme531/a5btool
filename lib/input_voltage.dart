///input_voltage.dart --- 读取输入电压
///通过读取saradc6的值来计算电压
///应该不需要root权限

import 'dart:io';
import 'dart:math';

double? getInputVoltage() {
  var processResult = Process.runSync(
      'cat', ['/sys/bus/iio/devices/iio:device0/in_voltage6_raw']);
  if (processResult.exitCode != 0) {
    return null;
  }
  var value = int.parse(processResult.stdout.toString().trim());
  //12bit adc, 8.2k/100k 分压电阻, 1.8v参考电压
  return value / pow(2, 12) * 1.8 * (100 + 8.2) / 8.2;
}
