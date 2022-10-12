import 'dart:io';

///检测当前是否为root用户
///返回值: 是否为root用户
bool isRoot() {
  var processResult = Process.runSync('id', ['-u']);
  if (processResult.exitCode != 0) {
    return false;
  }
  return processResult.stdout.toString().trim() == '0';
}
