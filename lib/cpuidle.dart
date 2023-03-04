///cpuidle.dart -- 控制Linux cpuidle开关
import 'utils.dart';

import 'dart:io';

class CpuIdle {
  static const String _path = '/sys/devices/system/cpu/';

  bool setAllStatesForCpu(int cpu, bool enable) {
    if (!isRoot()) {
      return false;
    }
    final cpuPath = '$_path/cpu$cpu';
    if (!Directory(cpuPath).existsSync()) {
      return false;
    }
    final statePath = '$cpuPath/cpuidle/';
    final states = Directory(statePath).listSync();
    for (final state in states) {
      final name = state.path.split('/').last;
      final disablePath = '$statePath/$name/disable';
      if (File(disablePath).existsSync()) {
        File(disablePath).writeAsStringSync(enable ? '0' : '1');
      }
    }
    return true;
  }

  bool setAll(bool enable) {
    var result = true;
    final cpus = Directory(_path).listSync();
    for (final cpu in cpus) {
      final name = cpu.path.split('/').last;
      if (name.startsWith('cpu')) {
        final cpuNum = int.tryParse(name.substring(3));
        if (cpuNum != null) {
          result &= setAllStatesForCpu(cpuNum, enable);
        }
      }
    }
    return result;
  }

  List<bool>? getAllStatesForCpu(int cpu) {
    final cpuPath = '$_path/cpu$cpu';
    if (!Directory(cpuPath).existsSync()) {
      return null;
    }
    final statePath = '$cpuPath/cpuidle/';
    final states = Directory(statePath).listSync();
    states.removeWhere(
        (element) => element.path.lastIndexOf(RegExp(r'state\d')) == -1);
    states.sort((a, b) => int.parse(a.path.split('/').last.substring(5)));
    final result = <bool>[];
    for (final state in states) {
      final name = state.path.split('/').last;
      final disablePath = '$statePath/$name/disable';
      if (File(disablePath).existsSync()) {
        result.add(File(disablePath).readAsStringSync().trim() == '0');
      }
    }
    return result;
  }

  List<List<bool>>? getAll() {
    final cpus = Directory(_path).listSync();
    cpus.removeWhere(
        (element) => element.path.lastIndexOf(RegExp(r'cpu\d')) == -1);
    cpus.sort((a, b) => int.parse(a.path.split('/').last.substring(3))
        .compareTo(int.parse(b.path.split('/').last.substring(3))));

    //从cpu0开始
    final result = <List<bool>?>[];
    for (final cpu in cpus) {
      final name = cpu.path.split('/').last;
      if (name.startsWith('cpu')) {
        final cpuNum = int.tryParse(name.substring(3));
        if (cpuNum != null) {
          result.add(getAllStatesForCpu(cpuNum));
        }
      }
    }
    if (result.any((element) => element == null)) {
      return null;
    }
    return result.cast<List<bool>>();
  }
}
