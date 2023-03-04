## Rock 5B工具箱

```
使用方法: 5bcli [参数] <命令> [命令参数]
可用的命令:
  cpu_serial    获取cpu序列号
  lottery       获取体质抽奖结果
  input_voltage 读取输入电压
  board_rev     获取板子版本
  usbpd         获取当前PD供电状态
  cpuidle       控制cpuidle
    
可用的参数:
-h, --help       获取帮助
-v, --version    显示工具版本

此软件是开源项目, 如果觉得对你有用, 可以点点star: https://github.com/happyme531/a5btool
```

目前你可以从Release页面下载编译好的二进制文件, 或者自己编译.  

### 如何编译

首先安装Dart SDK, 然后执行:


```bash
dart pub get
dart pub run build_runner build
dart compile exe bin/5bcli.dart -o 5bcli
```