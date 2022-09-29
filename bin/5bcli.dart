import 'dart:io';

import 'package:a5btool/cpu_serial.dart';
import 'package:a5btool/cpu_lottery.dart';
import 'package:a5btool/input_voltage.dart';
import 'package:a5btool/board_rev.dart';
import 'package:a5btool/generated/version.dart';

import 'package:args/args.dart';

/// Usage: 5bcli <命令> [参数]
/// 命令:
///  cpu_serial    获取cpu序列号
///  lottery       获取体质抽奖结果
///  input_voltage 读取输入电压
/// board_rev     获取板子版本
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
  lotteryParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //读取输入电压
  var inputVoltageParser = ArgParser();
  parser.addCommand('input_voltage', inputVoltageParser);
  inputVoltageParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  //获取板子版本
  var boardRevParser = ArgParser();
  parser.addCommand('board_rev', boardRevParser);
  boardRevParser.addFlag('help', abbr: 'h', negatable: false, help: '获取帮助');

  var results = parser.parse(arguments);

  var helpText = '''
使用方法: $selfName [参数] <命令> [命令参数]
可用的命令:
  cpu_serial    获取cpu序列号
  lottery       获取体质抽奖结果
  input_voltage 读取输入电压
  board_rev     获取板子版本
    
可用的参数:${parser.usage}
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
      var frequencies = getFreqBigClustersMHz();
      if (frequencies == null) {
        print("获取cpu频率失败");
        return 1;
      }
      const Map<CpuLotteryResult, String> lotteryMap = {
        CpuLotteryResult.level1: "一等奖",
        CpuLotteryResult.level2: "二等奖",
        CpuLotteryResult.level3: "三等奖",
        CpuLotteryResult.levelWorst: "参与奖",
      };
      var result0 = getCpuLotteryResult(frequencies[0]);
      var result1 = getCpuLotteryResult(frequencies[1]);

      print("第一组大核频率: ${frequencies[0]}MHz, 抽奖结果: ${lotteryMap[result0]}");
      print("第二组大核频率: ${frequencies[1]}MHz, 抽奖结果: ${lotteryMap[result1]}");
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
  }
  return 0;
}
