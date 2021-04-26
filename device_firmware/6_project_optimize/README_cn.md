# Performance Optimize 示例

该工程在书中的《第 12 章 电源管理与低功耗优化》进行介绍并使用。

功能：

1. 持续打印 "Hello World" 日志
2. 可通过物理开关控制 Light 开关状态
3. 可通过本项目搭配的 App 进行网络配置、Light 控制、固件升级等操作

相关文档：

1. [Performance](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/api-guides/performance/index.html)
2. [Power Management](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/api-reference/system/power_management.html)

优化内容：

1. 启动时间，跳过校验过程，能让 Light 尽快工作起来
2. 固件大小，能使用 2M Flash
3. 功耗优化，当 LEDC 使用 APB 时钟源时，能够在关灯的时候进入低功耗模式

## 开发环境搭建

根据您的开发板上使用的乐鑫芯片选择开发环境搭建指导文档：

- [ESP32-C3 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/get-started/index.html)

这个示例工程使用了 RainMaker，需要单独下载相关的代码：

```shell
$ cd </path/to/esp-rainmaker/>
$ git clone --recursive https://github.com/espressif/esp-rainmaker.git
$ cd esp-rainmaker
$ git checkout 948ed9db49c9cc715b386c5aca4898555e72812b
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
