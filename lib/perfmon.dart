import 'dart:io';
import 'package:ansicolor/ansicolor.dart';

abstract class PerfmonDataSource {
  void init() {}

  String getCsvHeader() {
    return '';
  }

  String getCsvLine() {
    return '';
  }

  String getUserFriendlyLine() {
    return '';
  }
}

AnsiPen pen = AnsiPen();
String colorPercentage(int percentage) {
  // 0-20: blue
  // 20-40: cyan
  // 40-60: green
  // 60-80: magenta
  // 80-90: yellow
  // 90-100: red
  if (percentage < 20) {
    pen..blue();
  } else if (percentage < 40) {
    pen..cyan();
  } else if (percentage < 60) {
    pen..green();
  } else if (percentage < 80) {
    pen..magenta();
  } else if (percentage < 90) {
    pen..yellow();
  } else {
    pen..red();
  }
  return pen(percentage.toString()) + '%';
}

class CpuNormalizedDataSource extends PerfmonDataSource {
  static const path = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq';
  static const header_cpu_freq = 'cpu_freq_mhz';

  int _getData() {
    var str = File(path).readAsStringSync();
    return int.parse(str) ~/ 1000;
  }

  @override
  void init() {
    if (!File(path).existsSync()) {
      throw Exception('CPU data source not found');
    }
    _getData();
  }

  @override
  String getCsvHeader() {
    return header_cpu_freq;
  }

  @override
  String getCsvLine() {
    var data = _getData();
    return data.toString();
  }

  @override
  String getUserFriendlyLine() {
    var data = _getData();
    return 'CPU freq: ${(data / 1000).toStringAsFixed(1)}GHz';
  }
}

class GpuDataSource extends PerfmonDataSource {
  static const path = '/sys/class/devfreq/fb000000.gpu/load';
  static RegExp regex = RegExp(r'(\d+)@(\d+)Hz');
  static const header_gpu_load = 'gpu_load';
  static const header_gpu_freq = 'gpu_freq_mhz';

  List<int> _getData() {
    var str = File(path).readAsStringSync();
    var matches = regex.firstMatch(str);
    if (matches?.groupCount != 2) {
      throw Exception('Cannot parse GPU data source: $str');
    }
    return [
      int.parse(matches!.group(1)!),
      int.parse(matches.group(2)!) ~/ 1000000
    ];
  }

  @override
  void init() {
    if (!File(path).existsSync()) {
      throw Exception('GPU data source not found');
    }
    _getData();
  }

  @override
  String getCsvHeader() {
    return '$header_gpu_load,$header_gpu_freq';
  }

  @override
  String getCsvLine() {
    var data = _getData();
    return '${data[0]},${data[1]}';
  }

  @override
  String getUserFriendlyLine() {
    var data = _getData();
    return 'GPU load: ${colorPercentage(data[0])}, freq: ${(data[1] / 1000).toStringAsFixed(1)}GHz';
  }
}

class DdrDataSource extends PerfmonDataSource {
  static const path = '/sys/class/devfreq/dmc/load';
  static RegExp regex = RegExp(r'(\d+)@(\d+)Hz');
  static const header_ddr_load = 'ddr_load';
  static const header_ddr_freq = 'ddr_freq_mhz';

  List<int> _getData() {
    var str = File(path).readAsStringSync();
    var matches = regex.firstMatch(str);
    if (matches?.groupCount != 2) {
      throw Exception('Cannot parse DDR data source: $str');
    }
    return [
      int.parse(matches!.group(1)!),
      int.parse(matches.group(2)!) ~/ 1000000
    ];
  }

  @override
  void init() {
    if (!File(path).existsSync()) {
      throw Exception('DDR data source not found');
    }
    _getData();
  }

  @override
  String getCsvHeader() {
    return '$header_ddr_load,$header_ddr_freq';
  }

  @override
  String getCsvLine() {
    var data = _getData();
    return '${data[0]},${data[1]}';
  }

  @override
  String getUserFriendlyLine() {
    var data = _getData();
    return 'DDR load: ${colorPercentage(data[0])}, freq: ${(data[1] / 1000).toStringAsFixed(1)}GHz';
  }
}

class NpuDataSource extends PerfmonDataSource {
  static const path = '/sys/kernel/debug/rknpu/load';
  //Core0:  0%, Core1:  0%, Core2:  0%
  static RegExp regex =
      RegExp(r'Core0:\s+(\d+)%, Core1:\s+(\d+)%, Core2:\s+(\d+)%');
  static const header_npu_load = 'npu_load';

  List<int> _getData() {
    var str = File(path).readAsStringSync();
    var matches = regex.firstMatch(str);
    if (matches?.groupCount != 3) {
      throw Exception('Cannot parse NPU data source: $str');
    }
    return [
      int.parse(matches!.group(1)!),
      int.parse(matches.group(2)!),
      int.parse(matches.group(3)!)
    ];
  }

  @override
  void init() {
    if (!File(path).existsSync()) {
      throw Exception('NPU data source not found');
    }
    _getData();
  }

  @override
  String getCsvHeader() {
    return '${header_npu_load}_0,${header_npu_load}_1,${header_npu_load}_2';
  }

  @override
  String getCsvLine() {
    var data = _getData();
    return '${data[0]},${data[1]},${data[2]}';
  }

  @override
  String getUserFriendlyLine() {
    var data = _getData();
    return 'NPU load: ${colorPercentage(data[0])}, ${colorPercentage(data[1])}, ${colorPercentage(data[2])}';
  }
}

class RgaDataSource extends PerfmonDataSource {
  static const path = '/sys/kernel/debug/rkrga/load';
  /*
  num of scheduler = 3
================= load ==================
scheduler[0]: rga3_core0
         load = 0%
-----------------------------------
scheduler[1]: rga3_core1
         load = 0%
-----------------------------------
scheduler[2]: rga2
         load = 0%
-----------------------------------
  */
  static RegExp regex = RegExp(r'load = (\d+)%');
  static const header_rga_load = 'rga_load';

  List<int> _getData() {
    var str = File(path).readAsStringSync();
    var matches = regex.allMatches(str);
    if (matches.length != 3) {
      throw Exception('Cannot parse RGA data source: $str');
    }
    return [
      int.parse(matches.elementAt(0).group(1)!),
      int.parse(matches.elementAt(1).group(1)!),
      int.parse(matches.elementAt(2).group(1)!)
    ];
  }

  @override
  void init() {
    if (!File(path).existsSync()) {
      throw Exception('RGA data source not found');
    }
    _getData();
  }

  @override
  String getCsvHeader() {
    return '${header_rga_load}_3_0,${header_rga_load}_3_1,${header_rga_load}_2';
  }

  @override
  String getCsvLine() {
    var data = _getData();
    return '${data[0]},${data[1]},${data[2]}';
  }

  @override
  String getUserFriendlyLine() {
    var data = _getData();
    return 'RGA load: ${colorPercentage(data[0])}, ${colorPercentage(data[1])}, ${colorPercentage(data[2])}';
  }
}

class Perfmon {
  static List<PerfmonDataSource> dataSources = [
    GpuDataSource(),
    DdrDataSource(),
    NpuDataSource(),
    RgaDataSource(),
  ];

  List<bool> _availibilities = [];

  void init() {
    for (var dataSource in dataSources) {
      try {
        dataSource.init();
        _availibilities.add(true);
      } catch (e) {
        print(e);
        _availibilities.add(false);
      }
    }
  }

  bool isAvailable(int index) {
    return _availibilities[index];
  }

  String getCsvHeader() {
    var header = '';
    header += 'time,';
    for (var i = 0; i < dataSources.length; i++) {
      if (isAvailable(i)) {
        header += dataSources[i].getCsvHeader() + ',';
      }
    }
    return header;
  }

  String getCsvLine() {
    var line = '';
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    line += currentTime.toString() + ',';
    for (var i = 0; i < dataSources.length; i++) {
      if (isAvailable(i)) {
        line += dataSources[i].getCsvLine() + ',';
      }
    }
    return line;
  }

  String getUserFriendlyMessage() {
    var message = '';
    for (var i = 0; i < dataSources.length; i++) {
      if (isAvailable(i)) {
        message += dataSources[i].getUserFriendlyLine() + '\n';
      }
    }
    return message;
  }
}
