import 'package:test/test.dart';

import 'package:a5btool/cpu_serial.dart';

void main() {
  test('cpu_serial', () {
    //应该是16位的字符串
    expect(getCpuSerial()?.length, 16);
  });
}
