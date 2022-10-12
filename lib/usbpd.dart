///usbpd.dart --- 读取usb pd信息
///
///需要root权限

import 'dart:cli';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'utils.dart';

const String debugfsPath = '/sys/kernel/debug/usb/';
const String tcpmLogFileRegexp = r'tcpm-\d*-\d*';

const String flushLogPath = '/tmp/5btool/tcpm_log.log';

//[    2.081895]  PDO 0: type 0, 5000 mV, 3000 mA [E]
//[    2.081934]  PDO 5: type 3, 3300-21000 mV, 3000 mA
const String pdoRegexp = r'PDO (\d+): type (\d+), (\d+|\d+-\d+) mV, (\d+) mA';

///usbpd PDO
class PDO implements Comparable<PDO> {
  ///排序用的值
  late int index;

  ///类型, 我也不知道是什么意思
  late int type;

  ///电压, 单位mv. 如果是可变电压, 则为最小电压
  late int voltage0;

  ///如果是可变电压, 则为最大电压, 否则应该置为0
  late int voltage1;

  ///电流, 单位ma
  late int current;

  @override
  bool operator ==(Object other) {
    if (other is PDO) {
      return type == other.type &&
          voltage0 == other.voltage0 &&
          voltage1 == other.voltage1 &&
          current == other.current;
    }
    return false;
  }

  @override
  int get hashCode =>
      type.hashCode ^ voltage0.hashCode ^ voltage1.hashCode ^ current.hashCode;

  @override
  String toString() {
    return 'PDO{type: $type, voltage0: $voltage0, voltage1: $voltage1, current: $current}';
  }

  @override
  int compareTo(PDO other) {
    if (index != other.index) {
      return index - other.index;
    }
    if (type != other.type) {
      return type - other.type;
    }
    if (voltage0 != other.voltage0) {
      return voltage0 - other.voltage0;
    }
    if (voltage1 != other.voltage1) {
      return voltage1 - other.voltage1;
    }
    return current - other.current;
  }
}

List<PDO> pdos = [];

///flush tcpm 日志
///需要root权限
///返回值: 是否成功
///如果成功, 则日志文件路径为/tmp/5btool/tcpm_log.log

bool flushTcpmLog() {
  if (!isRoot()) {
    return false;
  }
  var dir = Directory(path.dirname(flushLogPath));
  if (!dir.existsSync()) {
    dir.createSync();
  }
  var file = File(flushLogPath);
  //打开文件
  var sink = file.openWrite(mode: FileMode.append);
  //获取tcpm日志
  var tcpmLogDir = Directory(debugfsPath);
  var tcpmLogList = tcpmLogDir.listSync();
  for (var tcpmLog in tcpmLogList) {
    if (tcpmLog is File) {
      var tcpmLogName = path.basename(tcpmLog.path);
      if (RegExp(tcpmLogFileRegexp).hasMatch(tcpmLogName)) {
        var tcpmLogContent = tcpmLog.readAsStringSync();
        if (tcpmLogContent.isNotEmpty) {
          sink.write(tcpmLogContent);
        }
      }
    }
  }

  // ignore: deprecated_member_use
  waitFor(sink.flush());
  //关闭文件
  sink.close();

  return true;
}

List<PDO>? parseTcpmLog() {
  var file = File(flushLogPath);
  if (!file.existsSync()) {
    return null;
  }
  //清空pdos
  pdos.clear();

  var content = file.readAsStringSync();
  var lines = content.split('\n');

  for (var line in lines) {
    var match = RegExp(pdoRegexp).firstMatch(line);
    if (match != null) {
      var pdo = PDO();
      pdo.index = int.parse(match.group(1)!);
      pdo.type = int.parse(match.group(2)!);

      if (match.group(3)!.contains('-')) {
        var voltages = match.group(3)!.split('-');
        pdo.voltage0 = int.parse(voltages[0]);
        pdo.voltage1 = int.parse(voltages[1]);
      } else {
        pdo.voltage0 = int.parse(match.group(3)!);
        pdo.voltage1 = 0;
      }
      pdo.current = int.parse(match.group(4)!);
      pdos.add(pdo);
    }
  }
  pdos.sort();
  return pdos;
}

String? getRawTcpmLog() {
  var file = File(flushLogPath);
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsStringSync();
}
