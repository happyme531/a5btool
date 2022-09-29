///cpu_lottery.dart --- CPU体质大抽奖！
///读取CPU大核的最高频率，判断体质
///应该不需要root权限

import 'dart:io';

enum CpuLotteryResult {
  level1,
  level2,
  level3,
  level4,
  level5,
  levelWorst,
}

const Map freq2LevelMap = {
  2250: CpuLotteryResult.levelWorst,
  2300: CpuLotteryResult.level3,
  2350: CpuLotteryResult.level2,
  2400: CpuLotteryResult.level1,
};

const String cpuFreqPathBigCluster1 =
    '/sys/devices/system/cpu/cpufreq/policy4/cpuinfo_max_freq';
const String cpuFreqPathBigCluster2 =
    '/sys/devices/system/cpu/cpufreq/policy6/cpuinfo_max_freq';

List? getFreqBigClustersMHz() {
  var processResult =
      Process.runSync('cat', [cpuFreqPathBigCluster1, cpuFreqPathBigCluster2]);
  if (processResult.exitCode != 0) {
    return null;
  }
  var lines = processResult.stdout.toString().split('\n');
  lines.removeWhere((element) => element.isEmpty);

  return lines.map((e) => int.parse(e.trim()) ~/ 1000).toList();
}

CpuLotteryResult getCpuLotteryResult(int freqMHz) {
  var minimalFreq = 999999;
  for (var key in freq2LevelMap.keys) {
    if (key < minimalFreq) {
      minimalFreq = key;
    }
  }

  if (freqMHz < minimalFreq) {
    return CpuLotteryResult.levelWorst;
  }

  var min = 2400;
  var minKey = 0;
  freq2LevelMap.forEach((key, v) {
    var diff = (key - freqMHz).abs();
    if (diff < min) {
      min = diff;
      minKey = key;
    }
  });
  return freq2LevelMap[minKey];
}
