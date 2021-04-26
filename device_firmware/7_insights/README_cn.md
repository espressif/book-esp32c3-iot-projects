# RainMaker Insights 示例

该工程在书中的《第 15 章 ESP Insight 远程监察平台》进行介绍并使用。

功能：

1. 持续打印 "Hello World" 日志
2. 可通过物理开关控制 Light 开关状态
3. 可通过 `ESP RainMaker` App 进行网络配置、Light 控制、固件升级等操作
4. 支持 ESP-Insights 诊断功能

相关文档：

1. [SoftAP 和 BLE 配网](https://docs.espressif.com/projects/esp-jumpstart/zh_CN/latest/networkconfig.html#softap-ble)
2. [远程控制（云端）](https://docs.espressif.com/projects/esp-jumpstart/zh_CN/latest/remotecontrol.html)
3. [固件升级](https://docs.espressif.com/projects/esp-jumpstart/zh_CN/latest/firmwareupgrade.html)

## 开发环境搭建

根据您的开发板上使用的乐鑫芯片选择开发环境搭建指导文档：

- [ESP32-C3 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/get-started/index.html)

这个示例工程使用了 RainMaker，需要单独下载相关的代码：

```shell
$ cd </path/to/esp-rainmaker/>
$ git clone --recursive https://github.com/espressif/esp-rainmaker.git
$ cd esp-rainmaker
$ git checkout d4eb2f4fcab04fa625d502a12ece202d7d949c08
$ export RAIMAKER_PATH="$PWD"
```

## 编译、烧录

使用以下命令编译、烧录、监视：

```shell
$ export RAIMAKER_PATH=</path/to/esp-rainmaker/>
$ idf.py -p /dev/ttyUSBx -b 460800 flash monitor
```

## 示例工程结构

以下是项目文件夹中文件的简短说明：

```
├── main
│   ├── app_driver.c
│   ├── app_main.c
│   ├── CMakeLists.txt
│   └── include
│       ├── app_priv.h
│       └── board_esp32c3_devkitc.h
│   └── server.crt
├── partitions.csv              Partition table file
├── README_cn.md                This is the file you are currently reading
├── sdkconfig                   Project current configuration
└── sdkconfig.defaults          Project default configuration├── CMakeLists.txt
```

## 技术支持和反馈

请使用以下反馈渠道：

* 技术问题请到 [《ESP32-C3 物联网工程开发实战》书籍讨论版](https://esp32.com/)
* 对于功能请求或错误报告，请创建 [GitHub 问题](https://github.com/espressif/book-esp32c3-iot-projects/issues)

我们会尽快回复您。
