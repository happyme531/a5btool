import 'dart:io';
import 'dart:core';

import 'package:a5btool/cpu_serial.dart';
import 'package:a5btool/cpu_lottery.dart';
import 'package:a5btool/input_voltage.dart';
import 'package:a5btool/board_rev.dart';
import 'package:a5btool/usbpd.dart';
import 'package:a5btool/cpuidle.dart';
import 'package:a5btool/perfmon.dart';
import 'package:a5btool/generated/version.dart';

import 'package:args/args.dart';

/// Usage: 5bcli <命令> [参数]
/// 命令:
///  cpu_serial    获取cpu序列号
///  lottery       获取体质抽奖结果
///  input_voltage 读取输入电压
///  board_rev     获取板子版本
///  usbpd         获取usbpd信息
///  perfmon       性能监控
///
int main(List<String> arguments) {
  String selfName = Platform.executable.split(Platform.pathSeparator).last;
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');
  parser.addFlag('version', abbr: 'v', negatable: false, help: '显示工具版本');

  //获取cpu序列号
  var cpuSerialParser = ArgParser();
  parser.addCommand('cpu_serial', cpuSerialParser);
  cpuSerialParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //获取体质抽奖结果
  var lotteryParser = ArgParser();
  parser.addCommand('lottery', lotteryParser);
  lotteryParser.addFlag('list', abbr: 'l', negatable: false, help: '列出所有结果');
  lotteryParser.addFlag('legacy', negatable: false, help: '使用旧版方式获取体质抽奖结果');
  lotteryParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //读取输入电压
  var inputVoltageParser = ArgParser();
  parser.addCommand('input_voltage', inputVoltageParser);
  inputVoltageParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //获取板子版本
  var boardRevParser = ArgParser();
  parser.addCommand('board_rev', boardRevParser);
  boardRevParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //获取usbpd信息
  var usbpdParser = ArgParser();
  parser.addCommand('usbpd', usbpdParser);
  usbpdParser.addFlag('raw', negatable: false, help: '获取原始的TCPM日志');
  usbpdParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //控制cpuidle
  var cpuidleParser = ArgParser();
  parser.addCommand('cpuidle', cpuidleParser);
  cpuidleParser.addOption('cpu', abbr: 'c', help: '指定cpu编号, 0开始, 默认为所有cpu');
  cpuidleParser.addFlag('disable', negatable: false, help: '禁用cpuidle');
  cpuidleParser.addFlag('enable', negatable: false, help: '启用cpuidle');
  cpuidleParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //性能监控
  var perfmonParser = ArgParser();
  parser.addCommand('perfmon', perfmonParser);
  perfmonParser.addFlag('csv', negatable: false, help: '输出csv格式');
  perfmonParser.addOption('interval', abbr: 'i', help: '指定采样间隔, 单位为秒, 默认为1');
  perfmonParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  var results = parser.parse(arguments);

  var helpText = '''
使用方法: $selfName [参数] <命令> [命令参数]
可用的命令:
  cpu_serial    获取cpu序列号
  lottery       获取体质抽奖结果
  input_voltage 读取输入电压
  board_rev     获取板子版本
  usbpd         获取当前PD供电状态
  cpuidle       控制cpuidle
  perfmon       性能监控

可用的参数:
${parser.usage}

此软件是开源项目, 如果觉得对你有用, 可以点点star: https://github.com/happyme531/a5btool
''';

  if (results['help']) {
    print(helpText);
    return 0;
  }

  if (results['version']) {
    print('$selfName 版本: $packageVersion');
    return 0;
  }

  if (results.command == null) {
    print('未指定命令');
    print(helpText);
    return 0;
  }

  switch (results.command!.name) {
    case 'cpu_serial':
      if (results.command!['help']) {
        print(cpuSerialParser.usage);
        return 0;
      }
      var result = getCpuSerial();
      if (result == null) {
        print('获取cpu序列号失败');
        return 1;
      }
      print("CPU序列号: ${result}");
      break;
    case 'lottery':
      if (results.command!['help']) {
        print(lotteryParser.usage);
        return 0;
      }
      const Map<CpuLotteryResult, String> lotteryMap = {
        CpuLotteryResult.level1: "一等奖",
        CpuLotteryResult.level2: "二等奖",
        CpuLotteryResult.level3: "三等奖",
        CpuLotteryResult.levelWorst: "参与奖",
      };

      if (results.command!['list']) {
        print("所有体质抽奖结果:");
        if (results.command!['legacy']) {
          freq2LevelMap.forEach((key, value) {
            print("频率近似值: $key, 结果: ${lotteryMap[value]}");
          });
        } else {
          var lastValue = -1;
          var lastResult = CpuLotteryResult.levelWorst;
          pvtm2LevelMap.forEach((key, value) {
            if (lastValue != -1) {
              print(
                  "PVTM值: $lastValue - ${key - 1}, 结果: ${lotteryMap[lastResult]}");
            }
            lastValue = key;
            lastResult = value;
          });
        }
        return 0;
      }

      if (results.command!['legacy']) {
        var frequencies = getFreqBigClustersMHz();
        if (frequencies == null) {
          print("获取cpu频率失败");
          return 1;
        }

        var result0 = getCpuLotteryResult(frequencies[0]);
        var result1 = getCpuLotteryResult(frequencies[1]);

        print("第一组大核频率: ${frequencies[0]}MHz, 抽奖结果: ${lotteryMap[result0]}");
        print("第二组大核频率: ${frequencies[1]}MHz, 抽奖结果: ${lotteryMap[result1]}");
        print("抽奖结果受温度影响, 可以在不同温度下多次测试以获得更准确的结果");
        print("使用 --list 参数以列出所有可能结果");
      } else {
        try {
          var pvtmValues = getPvtmBigClusters();
          if (pvtmValues == null) {
            print("获取pvtm失败");
            return 1;
          }

          var result0 = getPvtmCpuLotteryResult(pvtmValues[0]);
          var result1 = getPvtmCpuLotteryResult(pvtmValues[1]);

          print("第一组大核pvtm值: ${pvtmValues[0]}, 抽奖结果: ${lotteryMap[result0]}");
          print("第二组大核pvtm值: ${pvtmValues[1]}, 抽奖结果: ${lotteryMap[result1]}");
          print("抽奖结果受温度影响, 可以在不同温度下多次测试以获得更准确的结果");
          print("使用 --list 参数以列出所有可能结果");
        } catch (e) {
          print("体质抽奖失败: $e");
        }
      }

      break;
    case 'input_voltage':
      if (results.command!['help']) {
        print(inputVoltageParser.usage);
        return 0;
      }
      var result = getInputVoltage();
      if (result == null) {
        print("获取输入电压失败");
        return 1;
      }

      print("输入电压: ${result.toStringAsFixed(2)}V");
      break;
    case 'board_rev':
      if (results.command!['help']) {
        print(boardRevParser.usage);
        return 0;
      }
      var result = getBoardRev();
      if (result == null) {
        print("获取板子版本失败");
        return 1;
      }
      print("板子版本: $result");
      break;
    case 'usbpd':
      if (results.command!['help']) {
        print(usbpdParser.usage);
        return 0;
      }
      bool result = flushTcpmLog();
      if (!result) {
        print("此命令需要root权限");
        return 1;
      }
      if (results.command!['raw']) {
        print(getRawTcpmLog());
      } else {
        List<PDO>? pdos = parseTcpmLog();
        if (pdos == null) {
          print("获取usbpd信息失败");
          return 1;
        }
        if (pdos.isEmpty) {
          print("未检测到usbpd信息, 可能在用5V2A供电");
          return 1;
        }
        print("你的充电器支持的电压电流:");
        for (var pdo in pdos) {
          if (pdo.voltage1 == 0)
            print(
                "${pdo.index + 1}: ${pdo.voltage0 / 1000.0}V, ${pdo.current / 1000.0}A");
          else
            print(
                "${pdo.index + 1}: ${pdo.voltage0 / 1000.0}-${pdo.voltage1 / 1000.0}V, ${pdo.current / 1000.0}A");
        }
      }
      break;

    case 'cpuidle':
      if (results.command!['help']) {
        print(cpuidleParser.usage);
        return 0;
      }
      var cpuIdle = CpuIdle();
      var operation = "none";
      if (results.command!['enable']) {
        operation = "enable";
      } else if (results.command!['disable']) {
        operation = "disable";
      }
      if (operation == "none") {
        var states = cpuIdle.getAll();
        if (states == null) {
          print("获取CPU空闲状态失败");
          return 1;
        }
        print("CPU空闲状态:");
        for (var i = 0; i < states.length; i++) {
          for (var j = 0; j < states[i].length; j++) {
            print("CPU $i, 状态 $j: ${states[i][j] ? "可用" : "不可用"}");
          }
        }
        return 1;
      }
      var affectedCpu = results.command!['cpu'];
      var res = false;
      if (affectedCpu == null) {
        res = cpuIdle.setAll(operation == "enable");
      } else {
        res = cpuIdle.setAllStatesForCpu(
            int.parse(affectedCpu), operation == "enable");
      }
      if (!res) {
        print("设置CPU空闲状态失败, 可能需要root权限");
        return 1;
      }
      break;

    case 'perfmon':
      if (results.command!['help']) {
        print(perfmonParser.usage);
        return 0;
      }
      var perfmon = Perfmon();
      perfmon.init();
      var interval = results.command!['interval'];
      double intervalValue = 1;
      if (interval != null) {
        intervalValue = double.parse(interval);
      }
      if (results.command!['csv']) {
        print(perfmon.getCsvHeader());
        while (true) {
          sleep(Duration(milliseconds: (intervalValue * 1000).toInt()));
          print(perfmon.getCsvLine());
        }
      } else {
        while (true) {
          sleep(Duration(milliseconds: (intervalValue * 1000).toInt()));
          var currentTime = DateTime.now().toIso8601String();
          print("\x1b[2J\x1b[H"); //清除屏幕
          print("5bcli 性能监控 - ${intervalValue}s - $currentTime");
          print(perfmon.getUserFriendlyMessage());
        }
      }
  }
  return 0;
}
