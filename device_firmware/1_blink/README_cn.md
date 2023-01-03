# Blink 示例

该工程在书中的《第 4 章 开发环境搭建与详解》进行介绍并使用。

功能：

1. 持续打印 "Hello World" 日志
2. 控制 LED 灯闪烁。（注意：ESP32-C3-Lyra 或 ESP32-C3-DevKitM-1 开发板上的 LED 是不适用 Blink 例程的， 因为其为单线控制 LED，WS2812 或 SK68xx，可以参考相关例程 esp-idf/examples/peripherals/rmt/led_strip）

## 开发环境搭建

根据您的开发板上使用的乐鑫芯片选择开发环境搭建指导文档：

- [ESP32-C3 Getting Started Guide](https://docs.espressif.com/projects/esp-idf/en/v4.3.2/esp32c3/get-started/index.html)

## 编译、烧录

使用以下命令编译、烧录、监视：

```shell
$ idf.py -p /dev/ttyUSBx -b 460800 flash monitor
```

## 示例工程结构

**blink** 项目包含一个 C 语言源文件 [blink.c](main/blink.c)。该文件位于文件夹 [main](main) 中。

ESP-IDF 项目是使用 CMake 构建的。项目构建配置包含在 `CMakeLists.txt` 文件中，这些文件提供了一组指令和说明，描述了项目的源文件和目标（可执行文件和/或库）。

以下是项目文件夹中文件的简短说明：

```
├── main
│   ├── CMakeLists.txt          Component CMakeLists used by CMake
│   ├── Kconfig.projbuild       Component Kconfig file
│   └── blink.c                 Source file
├── CMakeLists.txt              Project CMakeLists used by CMake
└── README_cn.md                This is the file you are currently reading
└── sdkconfig.defaults          Project default configuration
```

## 技术支持和反馈

请使用以下反馈渠道：

* 技术问题请到 [《ESP32-C3 物联网工程开发实战》书籍讨论版](https://esp32.com/)
* 对于功能请求或错误报告，请创建 [GitHub 问题](https://github.com/espressif/book-esp32c3-iot-projects/issues)

我们会尽快回复您。
